package com.elvencode.schoolba.auth.controller;

import com.elvencode.schoolba.auth.dto.LoginOutcome;
import com.elvencode.schoolba.auth.dto.LoginRequest;
import com.elvencode.schoolba.auth.dto.LoginResponse;
import com.elvencode.schoolba.auth.dto.MfaRequiredResponse;
import com.elvencode.schoolba.auth.service.AuthenticationService;
import com.elvencode.schoolba.config.security.AuthProperties;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private static final int MAX_USER_AGENT_LENGTH = 512;

    private final AuthenticationService authenticationService;
    private final AuthProperties authProperties;

    public AuthController(AuthenticationService authenticationService, AuthProperties authProperties) {
        this.authenticationService = authenticationService;
        this.authProperties = authProperties;
    }

    @PostMapping(path = "/login", version = "1.0+")
    public ResponseEntity<LoginResponse> login(
            @Valid @RequestBody LoginRequest loginRequest,
            HttpServletRequest request
    ) {
        LoginOutcome outcome = authenticationService.login(loginRequest, sourceFingerprint(request));
        HttpStatus status = outcome.response() instanceof MfaRequiredResponse
                ? HttpStatus.ACCEPTED
                : HttpStatus.OK;
        ResponseEntity.BodyBuilder response = ResponseEntity.status(status)
                .cacheControl(CacheControl.noStore())
                .header(HttpHeaders.PRAGMA, "no-cache");
        if (outcome.hasRefreshToken()) {
            response.header(HttpHeaders.SET_COOKIE, refreshCookie(outcome.refreshToken()).toString());
        }
        return response.body(outcome.response());
    }

    private ResponseCookie refreshCookie(String token) {
        AuthProperties.RefreshCookie cookie = authProperties.refreshCookie();
        return ResponseCookie.from(cookie.name(), token)
                .httpOnly(true)
                .secure(cookie.secure())
                .sameSite(cookie.sameSite())
                .path("/api/auth")
                .maxAge(authProperties.session().absoluteTimeout())
                .build();
    }

    private String sourceFingerprint(HttpServletRequest request) {
        String userAgent = request.getHeader(HttpHeaders.USER_AGENT);
        if (userAgent == null) {
            userAgent = "";
        } else if (userAgent.length() > MAX_USER_AGENT_LENGTH) {
            userAgent = userAgent.substring(0, MAX_USER_AGENT_LENGTH);
        }
        return request.getRemoteAddr() + '\n' + userAgent;
    }
}
