package com.elvencode.schoolba.config.security;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

import java.time.Duration;
import java.util.List;

@Validated
@ConfigurationProperties(prefix = "app.auth")
public record AuthProperties(
        @Valid @NotNull Jwt jwt,
        @Valid @NotNull Session session,
        @Valid @NotNull Mfa mfa,
        @Valid @NotNull RateLimit rateLimit,
        @Valid @NotNull RefreshCookie refreshCookie,
        @Valid @NotNull Cors cors
) {

    public record Jwt(
            @NotBlank String issuer,
            @NotBlank String audience,
            @NotBlank String keyId,
            @NotBlank String signingKeyBase64,
            @NotNull Duration accessTokenTtl
    ) {
        @Override
        public String toString() {
            return "Jwt[issuer=" + issuer + ", audience=" + audience + ", keyId=" + keyId
                    + ", signingKeyBase64=[REDACTED], accessTokenTtl=" + accessTokenTtl + "]";
        }
    }

    public record Session(
            @NotNull Duration idleTimeout,
            @NotNull Duration absoluteTimeout
    ) {
    }

    public record Mfa(@NotNull Duration challengeTtl) {
    }

    public record RateLimit(
            @Min(1) int maxFailures,
            @NotNull Duration window
    ) {
    }

    public record RefreshCookie(
            @NotBlank String name,
            boolean secure,
            @NotBlank String sameSite
    ) {
    }

    public record Cors(@NotEmpty List<@NotBlank String> allowedOrigins) {
        public Cors {
            allowedOrigins = List.copyOf(allowedOrigins);
        }
    }
}
