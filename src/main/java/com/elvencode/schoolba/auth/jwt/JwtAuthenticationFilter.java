package com.elvencode.schoolba.auth.jwt;

import com.elvencode.schoolba.auth.entity.AuthenticatedPrincipal;
import com.elvencode.schoolba.auth.exception.InvalidAccessTokenException;
import com.elvencode.schoolba.auth.service.SessionAuthenticationService;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String BEARER_PREFIX = "Bearer ";
    private static final String UNAUTHORIZED_BODY =
            "{\"code\":\"UNAUTHORIZED\",\"message\":\"Authentication is required.\"}";

    private final JwtTokenService jwtTokenService;
    private final SessionAuthenticationService sessionAuthenticationService;

    public JwtAuthenticationFilter(
            JwtTokenService jwtTokenService,
            SessionAuthenticationService sessionAuthenticationService
    ) {
        this.jwtTokenService = jwtTokenService;
        this.sessionAuthenticationService = sessionAuthenticationService;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authorization == null) {
            filterChain.doFilter(request, response);
            return;
        }
        if (!authorization.regionMatches(true, 0, BEARER_PREFIX, 0, BEARER_PREFIX.length())) {
            writeUnauthorized(response);
            return;
        }

        String token = authorization.substring(BEARER_PREFIX.length()).strip();
        if (token.isEmpty()) {
            writeUnauthorized(response);
            return;
        }

        try {
            AccessTokenClaims claims = jwtTokenService.parse(token);
            AuthenticatedPrincipal principal = sessionAuthenticationService.authenticate(claims);
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(principal, null, List.of());
            SecurityContext context = SecurityContextHolder.createEmptyContext();
            context.setAuthentication(authentication);
            SecurityContextHolder.setContext(context);
            filterChain.doFilter(request, response);
        } catch (JwtException | IllegalArgumentException | InvalidAccessTokenException exception) {
            SecurityContextHolder.clearContext();
            writeUnauthorized(response);
        }
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getServletPath();
        return path.equals("/api/auth/login") || path.startsWith("/api/school/");
    }

    private void writeUnauthorized(HttpServletResponse response) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write(UNAUTHORIZED_BODY);
    }
}
