package com.elvencode.schoolba.auth.exception;

import com.elvencode.schoolba.auth.controller.AuthController;
import com.elvencode.schoolba.auth.dto.AuthErrorResponse;
import com.elvencode.schoolba.auth.dto.AuthValidationErrorResponse;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
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
        return noStore(HttpStatus.UNAUTHORIZED)
                .body(new AuthErrorResponse("AUTHENTICATION_FAILED", "Authentication failed."));
    }

    @ExceptionHandler(MfaEnrollmentRequiredException.class)
    public ResponseEntity<AuthErrorResponse> handleMfaEnrollmentRequired() {
        return noStore(HttpStatus.FORBIDDEN).body(new AuthErrorResponse(
                "MFA_ENROLLMENT_REQUIRED",
                "Multi-factor authentication enrollment is required."
        ));
    }

    @ExceptionHandler(LoginRateLimitExceededException.class)
    public ResponseEntity<AuthErrorResponse> handleRateLimit(LoginRateLimitExceededException exception) {
        return noStore(HttpStatus.TOO_MANY_REQUESTS)
                .header(HttpHeaders.RETRY_AFTER, Long.toString(exception.getRetryAfter().toSeconds()))
                .body(new AuthErrorResponse(
                        "LOGIN_RATE_LIMITED",
                        "Too many login attempts. Try again later."
                ));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<AuthValidationErrorResponse> handleValidation(
            MethodArgumentNotValidException exception
    ) {
        Map<String, String> fields = new LinkedHashMap<>();
        for (FieldError error : exception.getBindingResult().getFieldErrors()) {
            fields.putIfAbsent(error.getField(), error.getDefaultMessage());
        }
        return noStore(HttpStatus.BAD_REQUEST).body(new AuthValidationErrorResponse(
                "VALIDATION_FAILED",
                "The login request is invalid.",
                fields
        ));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<AuthErrorResponse> handleUnreadableRequest() {
        return noStore(HttpStatus.BAD_REQUEST).body(new AuthErrorResponse(
                "VALIDATION_FAILED",
                "The login request is invalid."
        ));
    }

    private ResponseEntity.BodyBuilder noStore(HttpStatus status) {
        return ResponseEntity.status(status)
                .cacheControl(CacheControl.noStore())
                .header(HttpHeaders.PRAGMA, "no-cache");
    }
}
