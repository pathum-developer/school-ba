package com.elvencode.schoolba.auth.jwt;

import com.elvencode.schoolba.auth.entity.LoginAccount;
import com.elvencode.schoolba.config.security.AuthProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.JwtParser;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

@Service
public class JwtTokenService {

    private static final Duration MAXIMUM_ACCESS_TOKEN_TTL = Duration.ofMinutes(10);

    private final AuthProperties.Jwt properties;
    private final Clock clock;
    private final SecretKey signingKey;
    private final JwtParser parser;

    public JwtTokenService(AuthProperties authProperties, Clock clock) {
        this.properties = authProperties.jwt();
        this.clock = clock;
        validateAccessTokenTtl(properties.accessTokenTtl());
        this.signingKey = decodeSigningKey(properties.signingKeyBase64());
        this.parser = Jwts.parser()
                .verifyWith(signingKey)
                .requireIssuer(properties.issuer())
                .requireAudience(properties.audience())
                .clock(() -> Date.from(clock.instant()))
                .clockSkewSeconds(30)
                .build();
    }

    public IssuedAccessToken issue(LoginAccount account, UUID sessionId) {
        Instant issuedAt = clock.instant();
        Instant expiresAt = issuedAt.plus(properties.accessTokenTtl());
        String token = Jwts.builder()
                .header()
                    .keyId(properties.keyId())
                    .and()
                .issuer(properties.issuer())
                .audience()
                    .add(properties.audience())
                    .and()
                .subject(account.id().toString())
                .claim("sid", sessionId.toString())
                .claim("av", account.authorizationVersion())
                .claim("cv", account.credentialVersion())
                .issuedAt(Date.from(issuedAt))
                .expiration(Date.from(expiresAt))
                .id(UUID.randomUUID().toString())
                .signWith(signingKey)
                .compact();
        return new IssuedAccessToken(token, expiresAt);
    }

    public AccessTokenClaims parse(String token) {
        Jws<Claims> parsed = parser.parseSignedClaims(token);
        if (!properties.keyId().equals(parsed.getHeader().getKeyId())) {
            throw new IllegalArgumentException("Unexpected JWT signing key id.");
        }
        Claims claims = parsed.getPayload();
        return new AccessTokenClaims(
                UUID.fromString(claims.getSubject()),
                UUID.fromString(claims.get("sid", String.class)),
                numberClaim(claims, "av"),
                numberClaim(claims, "cv")
        );
    }

    public Duration accessTokenTtl() {
        return properties.accessTokenTtl();
    }

    private long numberClaim(Claims claims, String name) {
        Object value = claims.get(name);
        if (!(value instanceof Number number)) {
            throw new IllegalArgumentException("Missing numeric JWT claim: " + name);
        }
        return number.longValue();
    }

    private SecretKey decodeSigningKey(String encodedKey) {
        try {
            return Keys.hmacShaKeyFor(Decoders.BASE64.decode(encodedKey));
        } catch (RuntimeException exception) {
            throw new IllegalStateException(
                    "JWT_SIGNING_KEY_BASE64 must contain a Base64-encoded key of at least 256 bits.",
                    exception
            );
        }
    }

    private void validateAccessTokenTtl(Duration ttl) {
        if (ttl.isZero() || ttl.isNegative() || ttl.compareTo(MAXIMUM_ACCESS_TOKEN_TTL) > 0) {
            throw new IllegalStateException("JWT access-token TTL must be positive and no greater than ten minutes.");
        }
    }

    public record IssuedAccessToken(String value, Instant expiresAt) {
        @Override
        public String toString() {
            return "IssuedAccessToken[value=[REDACTED], expiresAt=" + expiresAt + "]";
        }
    }
}
