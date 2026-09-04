package com.elvencode.schoolba.auth.jwt;

import java.util.List;
import java.util.Set;
import java.util.UUID;

import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;
import com.elvencode.schoolba.auth.dto.IdentityGrant;
import com.elvencode.schoolba.auth.enums.IdentityStatus;
import com.elvencode.schoolba.auth.enums.ScopeType;
import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The token is the only thing standing between what was decided at sign-in and what a later
 * request is allowed to do, so what matters here is that a principal written into a token comes
 * back out unchanged.
 */
class JwtUtilTest {

    private static final UUID IDENTITY_ID = UUID.fromString("70000000-0000-0000-0000-000000000001");
    private static final UUID SCHOOL_ID = UUID.fromString("20000000-0000-0000-0000-000000000001");
    private static final UUID STAFF_ID = UUID.fromString("60000000-0000-0000-0000-000000000001");
    private static final UUID BRANCH_ID = UUID.fromString("30000000-0000-0000-0000-000000000001");

    private JwtUtil jwtUtil;

    @BeforeEach
    void setUp() {
        jwtUtil = new JwtUtil(new MockEnvironment());
    }

    @Test
    void tokenCarriesTheWholePrincipalBackOutAgain() {
        AuthenticatedIdentity original = staffPrincipal(List.of(
                new IdentityGrant("branch:read", ScopeType.SCHOOL, SCHOOL_ID, null),
                new IdentityGrant("branch:create", ScopeType.SCHOOL, SCHOOL_ID, null)
        ));

        AuthenticatedIdentity restored = roundTrip(original);

        assertEquals(IDENTITY_ID, restored.getId());
        assertEquals("elven_super", restored.getUsername());
        assertEquals("Elven Super Admin", restored.getDisplayName());
        assertEquals(SCHOOL_ID, restored.getSchoolId());
        assertEquals(STAFF_ID, restored.getStaffId());
        assertEquals(7, restored.getAuthorizationVersion());
        assertEquals(
                List.of("branch:create", "branch:read"),
                restored.getAuthorities().stream().map(GrantedAuthority::getAuthority).toList()
        );
    }

    /**
     * The reason the grants are carried as objects rather than bare codes. Both entries below
     * are the same permission string, and only the scope says that one reaches a whole school
     * and the other a single branch.
     */
    @Test
    void tokenKeepsEachGrantApartByTheScopeItWasGrantedAt() {
        AuthenticatedIdentity original = staffPrincipal(List.of(
                new IdentityGrant("branch:read", ScopeType.SCHOOL, SCHOOL_ID, null),
                new IdentityGrant("branch:read", ScopeType.BRANCH, SCHOOL_ID, BRANCH_ID)
        ));

        AuthenticatedIdentity restored = roundTrip(original);

        assertEquals(Set.copyOf(original.getGrantList()), Set.copyOf(restored.getGrantList()));
        assertTrue(restored.getGrantList().stream()
                .anyMatch(grant -> grant.scopeType() == ScopeType.BRANCH && BRANCH_ID.equals(grant.branchId())));

        // One permission code, however many scopes carry it.
        assertEquals(
                List.of("branch:read"),
                restored.getAuthorities().stream().map(GrantedAuthority::getAuthority).toList()
        );
    }

    @Test
    void tokenLeavesOutThePersonLinkThatDoesNotApply() {
        Claims claims = jwtUtil.parseJwtToken(jwtUtil.generateJwtToken(authentication(staffPrincipal(List.of()))));

        assertEquals(STAFF_ID.toString(), claims.get("staffId", String.class));
        assertNull(claims.get("learnerId", String.class), "a staff login has no learner");
    }

    @Test
    void aPrincipalHoldingNoGrantComesBackWithNoAuthority() {
        AuthenticatedIdentity restored = roundTrip(staffPrincipal(List.of()));

        assertTrue(restored.getGrantList().isEmpty());
        assertTrue(restored.getAuthorities().isEmpty());
    }

    private AuthenticatedIdentity roundTrip(AuthenticatedIdentity identity) {
        String token = jwtUtil.generateJwtToken(authentication(identity));
        return jwtUtil.toPrincipal(jwtUtil.parseJwtToken(token));
    }

    private Authentication authentication(AuthenticatedIdentity identity) {
        return UsernamePasswordAuthenticationToken.authenticated(identity, null, identity.getAuthorities());
    }

    private AuthenticatedIdentity staffPrincipal(List<IdentityGrant> grantList) {
        return new AuthenticatedIdentity(
                IDENTITY_ID,
                "elven_super",
                "Elven Super Admin",
                SCHOOL_ID,
                STAFF_ID,
                null,
                IdentityStatus.ACTIVE,
                7,
                grantList
        );
    }
}
