package com.elvencode.schoolba.auth.jwt;

import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;
import com.elvencode.schoolba.auth.dto.IdentityGrant;
import com.elvencode.schoolba.auth.enums.IdentityStatus;
import com.elvencode.schoolba.auth.enums.ScopeType;
import com.elvencode.schoolba.common.constants.ApplicationConstant;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.core.env.Environment;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Writes and reads the tokens this application issues.
 *
 * <p>Both directions live here on purpose. The claim shape is a format, and a format whose
 * writer sits in one class and whose reader sits in another drifts the first time either moves.
 */
@Component
public class JwtUtil {

    private static final String JWT_ISSUER = "School Portal";
    private static final long JWT_EXPIRATION_MILLIS = 24 * 60 * 60 * 1000L;

    private final Environment env;

    public JwtUtil(Environment env) {
        this.env = env;
    }

    /**
     * Issues a token carrying the whole principal, so a request presenting it needs no database
     * read before it can be authorized.
     *
     * <p>The subject is the identity id, which is what a JWT subject is for: it names the
     * account the token was issued to. The tenant and person ids travel with it because an
     * authorization check needs them, and the grants keep their scope rather than collapsing to
     * bare codes, because a school-wide {@code branch:read} and a branch-scoped one are the same
     * string and only the scope separates them.
     *
     * <p>All of it is a snapshot taken at sign-in. Nothing re-reads it, so a role withdrawn or
     * an account suspended afterwards still holds until the token expires. The authorization
     * version travels along so a check against the stored value can be added later without
     * changing the format.
     */
    public String generateJwtToken(Authentication authentication) {
        AuthenticatedIdentity identity = principal(authentication);
        Date issuedAt = new Date();
        Date expiration = new Date(issuedAt.getTime() + JWT_EXPIRATION_MILLIS);

        return Jwts.builder()
                .issuer(JWT_ISSUER)
                .subject(identity.getId().toString())
                .claim(ApplicationConstant.JWT_USERNAME_CLAIM, identity.getUsername())
                .claim(ApplicationConstant.JWT_DISPLAY_NAME_CLAIM, identity.getDisplayName())
                .claim(ApplicationConstant.JWT_SCHOOL_ID_CLAIM, text(identity.getSchoolId()))
                .claim(ApplicationConstant.JWT_STAFF_ID_CLAIM, text(identity.getStaffId()))
                .claim(ApplicationConstant.JWT_LEARNER_ID_CLAIM, text(identity.getLearnerId()))
                .claim(ApplicationConstant.JWT_AUTHORIZATION_VERSION_CLAIM, identity.getAuthorizationVersion())
                .claim(ApplicationConstant.JWT_GRANT_LIST_CLAIM, grantListClaim(identity.getGrantList()))
                .issuedAt(issuedAt)
                .expiration(expiration)
                .signWith(secretKey())
                .compact();
    }

    public Claims parseJwtToken(String jwt) {
        return Jwts.parser()
                .verifyWith(secretKey())
                .build()
                .parseSignedClaims(jwt)
                .getPayload();
    }

    /**
     * Rebuilds the principal from a token whose signature has already been verified.
     *
     * <p>The status is taken to be active. A token is only ever issued to an account that could
     * sign in, and nothing here re-reads the row, so this states plainly what the rest of the
     * design already assumes rather than implying a check it does not perform.
     */
    public AuthenticatedIdentity toPrincipal(Claims claims) {
        return new AuthenticatedIdentity(
                UUID.fromString(claims.getSubject()),
                claims.get(ApplicationConstant.JWT_USERNAME_CLAIM, String.class),
                claims.get(ApplicationConstant.JWT_DISPLAY_NAME_CLAIM, String.class),
                uuid(claims.get(ApplicationConstant.JWT_SCHOOL_ID_CLAIM, String.class)),
                uuid(claims.get(ApplicationConstant.JWT_STAFF_ID_CLAIM, String.class)),
                uuid(claims.get(ApplicationConstant.JWT_LEARNER_ID_CLAIM, String.class)),
                IdentityStatus.ACTIVE,
                authorizationVersion(claims),
                grantList(claims)
        );
    }

    /**
     * Groups the grants by the scope they were made at, so a scope is written once however many
     * permissions share it. An account holding thirty permissions across one school writes one
     * entry rather than thirty copies of the same school id.
     */
    private List<Map<String, Object>> grantListClaim(List<IdentityGrant> grantList) {
        Map<GrantScope, List<String>> permissionCodeListByScope = new LinkedHashMap<>();
        for (IdentityGrant grant : grantList) {
            GrantScope scope = new GrantScope(grant.scopeType(), grant.schoolId(), grant.branchId());
            permissionCodeListByScope
                    .computeIfAbsent(scope, key -> new ArrayList<>())
                    .add(grant.permissionCode());
        }

        List<Map<String, Object>> claimList = new ArrayList<>(permissionCodeListByScope.size());
        permissionCodeListByScope.forEach((scope, permissionCodeList) -> {
            Map<String, Object> entry = new LinkedHashMap<>();
            entry.put(ApplicationConstant.JWT_GRANT_SCOPE_TYPE, scope.scopeType().name());
            putIfPresent(entry, ApplicationConstant.JWT_GRANT_SCHOOL_ID, text(scope.schoolId()));
            putIfPresent(entry, ApplicationConstant.JWT_GRANT_BRANCH_ID, text(scope.branchId()));
            entry.put(
                    ApplicationConstant.JWT_GRANT_PERMISSION_CODE_LIST,
                    permissionCodeList.stream().distinct().sorted().toList()
            );
            claimList.add(entry);
        });
        return claimList;
    }

    private List<IdentityGrant> grantList(Claims claims) {
        List<?> claimList = claims.get(ApplicationConstant.JWT_GRANT_LIST_CLAIM, List.class);
        if (claimList == null) {
            return List.of();
        }

        List<IdentityGrant> grantList = new ArrayList<>();
        for (Object element : claimList) {
            if (!(element instanceof Map<?, ?> entry)) {
                continue;
            }
            ScopeType scopeType = ScopeType.valueOf(
                    String.valueOf(entry.get(ApplicationConstant.JWT_GRANT_SCOPE_TYPE))
            );
            UUID schoolId = uuid(string(entry.get(ApplicationConstant.JWT_GRANT_SCHOOL_ID)));
            UUID branchId = uuid(string(entry.get(ApplicationConstant.JWT_GRANT_BRANCH_ID)));

            if (entry.get(ApplicationConstant.JWT_GRANT_PERMISSION_CODE_LIST) instanceof List<?> codeList) {
                for (Object permissionCode : codeList) {
                    grantList.add(new IdentityGrant(String.valueOf(permissionCode), scopeType, schoolId, branchId));
                }
            }
        }
        return List.copyOf(grantList);
    }

    private int authorizationVersion(Claims claims) {
        Integer version = claims.get(ApplicationConstant.JWT_AUTHORIZATION_VERSION_CLAIM, Integer.class);
        return version == null ? 0 : version;
    }

    private AuthenticatedIdentity principal(Authentication authentication) {
        if (authentication.getPrincipal() instanceof AuthenticatedIdentity identity) {
            return identity;
        }
        throw new IllegalStateException(
                "Cannot issue a token for principal of type "
                        + authentication.getPrincipal().getClass().getName()
        );
    }

    private static void putIfPresent(Map<String, Object> entry, String key, String value) {
        if (value != null) {
            entry.put(key, value);
        }
    }

    private static String text(UUID value) {
        return value == null ? null : value.toString();
    }

    private static String string(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static UUID uuid(String value) {
        return value == null ? null : UUID.fromString(value);
    }

    private SecretKey secretKey() {
        String secret = env.getProperty(
                ApplicationConstant.JWT_SECRET_KEY,
                ApplicationConstant.JWT_SECRET_DEFAULT_VALUE
        );
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    /** The reach one group of permissions was granted at. */
    private record GrantScope(ScopeType scopeType, UUID schoolId, UUID branchId) {
    }
}
