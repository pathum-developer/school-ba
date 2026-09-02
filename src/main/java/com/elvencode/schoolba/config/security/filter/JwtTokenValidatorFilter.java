package com.elvencode.schoolba.config.security.filter;

import com.elvencode.schoolba.auth.jwt.JwtUtil;
import com.elvencode.schoolba.common.constants.ApplicationConstant;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;

@Component
public class JwtTokenValidatorFilter extends OncePerRequestFilter {

    private static final String ROLE_PREFIX = "ROLE_";
    private static final String USERNAME_CLAIM = "username";
    private static final String ROLES_CLAIM = "roles";
    private static final String AUTHORITIES_CLAIM = "authorities";
    private static final String TOKEN_EXPIRED_MESSAGE = "Token expired";
    private static final String INVALID_TOKEN_MESSAGE = "Invalid token received";

    private final AntPathMatcher pathMatcher = new AntPathMatcher();
    private final List<String> publicPathList;
    private final JwtUtil jwtUtil;

    public JwtTokenValidatorFilter(@Qualifier("publicPaths") List<String> publicPathList,
                                   JwtUtil jwtUtil) {
        this.publicPathList = publicPathList;
        this.jwtUtil = jwtUtil;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String requestPath = request.getServletPath();
        return publicPathList.stream()
                .anyMatch(publicPath -> pathMatcher.match(publicPath, requestPath));
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String authHeader = request.getHeader(ApplicationConstant.JWT_HEADER);
        if (authHeader == null || !authHeader.startsWith(ApplicationConstant.JWT_TOKEN_PREFIX)) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            String jwt = authHeader.substring(ApplicationConstant.JWT_TOKEN_PREFIX.length());
            Claims claims = jwtUtil.parseJwtToken(jwt);
            Authentication authentication = new UsernamePasswordAuthenticationToken(
                    claims.get(USERNAME_CLAIM, String.class),
                    null,
                    authorityList(claims)
            );
            SecurityContextHolder.getContext().setAuthentication(authentication);
            filterChain.doFilter(request, response);
        } catch (ExpiredJwtException exception) {
            SecurityContextHolder.clearContext();
            writeUnauthorizedResponse(request, response, TOKEN_EXPIRED_MESSAGE);
        } catch (Exception exception) {
            SecurityContextHolder.clearContext();
            writeUnauthorizedResponse(request, response, INVALID_TOKEN_MESSAGE);
        }
    }

    private List<SimpleGrantedAuthority> authorityList(Claims claims) {
        List<?> authorityList = claims.get(AUTHORITIES_CLAIM, List.class);
        if (authorityList != null) {
            return authorityList.stream()
                    .map(String::valueOf)
                    .map(SimpleGrantedAuthority::new)
                    .toList();
        }

        List<?> roleList = claims.get(ROLES_CLAIM, List.class);
        if (roleList == null) {
            return List.of();
        }
        return roleList.stream()
                .map(String::valueOf)
                .map(this::authority)
                .map(SimpleGrantedAuthority::new)
                .toList();
    }

    private String authority(String role) {
        if (role.startsWith(ROLE_PREFIX)) {
            return role;
        }
        return ROLE_PREFIX + role;
    }

    private void writeUnauthorizedResponse(HttpServletRequest request,
                                           HttpServletResponse response,
                                           String message) throws IOException {
        response.setStatus(HttpStatus.UNAUTHORIZED.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write("""
                {"apiPath":"%s","errorCode":"%s","errorMessage":"%s","errorTime":"%s"}\
                """.formatted(
                request.getRequestURI(),
                HttpStatus.UNAUTHORIZED,
                message,
                LocalDateTime.now()
        ));
    }
}
