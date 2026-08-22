package com.elvencode.schoolba.auth.exception;

import com.elvencode.schoolba.auth.controller.AuthController;
import com.elvencode.schoolba.auth.dto.AuthErrorResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice(assignableTypes = AuthController.class)
public class AuthExceptionHandler {

    @ExceptionHandler(InvalidCredentialsException.class)
    public ResponseEntity<AuthErrorResponse> handleInvalidCredentials() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(new AuthErrorResponse("AUTHENTICATION_FAILED", "Authentication failed."));
    }

    @ExceptionHandler(MfaEnrollmentRequiredException.class)
    public ResponseEntity<AuthErrorResponse> handleMfaEnrollmentRequired() {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(new AuthErrorResponse(
                        "MFA_ENROLLMENT_REQUIRED",
                        "Multi-factor authentication enrollment is required."
                ));
    }

    @ExceptionHandler(LoginRateLimitExceededException.class)
    public ResponseEntity<AuthErrorResponse> handleRateLimit(LoginRateLimitExceededException exception) {
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                .header(HttpHeaders.RETRY_AFTER, Long.toString(exception.getRetryAfter().toSeconds()))
                .body(new AuthErrorResponse(
                        "LOGIN_RATE_LIMITED",
                        "Too many login attempts. Try again later."
                ));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<AuthErrorResponse> handleValidation(MethodArgumentNotValidException exception) {
        Map<String, String> fields = new LinkedHashMap<>();
        for (FieldError error : exception.getBindingResult().getFieldErrors()) {
            fields.putIfAbsent(error.getField(), error.getDefaultMessage());
        }
        return ResponseEntity.badRequest().body(new AuthErrorResponse(
                "VALIDATION_FAILED",
                "The login request is invalid.",
                fields
        ));
    }
}
