package com.elvencode.schoolba.config.security.filter;

import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;
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
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;

@Component
public class JwtTokenValidatorFilter extends OncePerRequestFilter {

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

            // The full principal, not a bare username: the claims carry the tenant and person
            // ids and the scope of every grant, so an authorization check has what it needs
            // without going back to the database.
            AuthenticatedIdentity identity = jwtUtil.toPrincipal(claims);
            Authentication authentication = UsernamePasswordAuthenticationToken.authenticated(
                    identity,
                    null,
                    identity.getAuthorities()
            );
            SecurityContextHolder.getContext().setAuthentication(authentication);
        } catch (ExpiredJwtException exception) {
            SecurityContextHolder.clearContext();
            writeUnauthorizedResponse(request, response, TOKEN_EXPIRED_MESSAGE);
            return;
        } catch (Exception exception) {
            SecurityContextHolder.clearContext();
            writeUnauthorizedResponse(request, response, INVALID_TOKEN_MESSAGE);
            return;
        }

        // Outside the try on purpose. Running the rest of the chain inside it would report any
        // failure downstream, in a controller or a service, as a rejected token.
        filterChain.doFilter(request, response);
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
