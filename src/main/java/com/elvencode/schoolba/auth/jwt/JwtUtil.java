package com.elvencode.schoolba.auth.jwt;

import com.elvencode.schoolba.common.constants.ApplicationConstant;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.core.env.Environment;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.List;

@Component
public class JwtUtil {

    private static final String ROLE_PREFIX = "ROLE_";
    private static final String JWT_ISSUER = "School Portal";
    private static final String JWT_SUBJECT = "JWT Token";
    private static final long JWT_EXPIRATION_MILLIS = 24 * 60 * 60 * 1000L;

    private final Environment env;

    public JwtUtil(Environment env) {
        this.env = env;
    }

    public String generateJwtToken(Authentication authentication) {
        Date issuedAt = new Date();
        Date expiration = new Date(issuedAt.getTime() + JWT_EXPIRATION_MILLIS);

        return Jwts.builder()
                .issuer(JWT_ISSUER)
                .subject(JWT_SUBJECT)
                .claim("username", authentication.getName())
                .claim("roles", roleList(authentication))
                .claim("authorities", authorityList(authentication))
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

    private List<String> roleList(Authentication authentication) {
        return authentication.getAuthorities()
                .stream()
                .map(GrantedAuthority::getAuthority)
                .filter(authority -> authority.startsWith(ROLE_PREFIX))
                .map(authority -> authority.substring(ROLE_PREFIX.length()))
                .toList();
    }

    private List<String> authorityList(Authentication authentication) {
        return authentication.getAuthorities()
                .stream()
                .map(GrantedAuthority::getAuthority)
                .toList();
    }

    private SecretKey secretKey() {
        String secret = env.getProperty(
                ApplicationConstant.JWT_SECRET_KEY,
                ApplicationConstant.JWT_SECRET_DEFAULT_VALUE
        );
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }
}
