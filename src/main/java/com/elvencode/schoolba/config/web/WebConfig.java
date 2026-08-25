package com.elvencode.schoolba.config.web;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.web.servlet.config.annotation.ApiVersionConfigurer;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.PathMatchConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    private static final MediaType ELVEN_API_MEDIA_TYPE =
            MediaType.parseMediaType("application/vnd.elven+json");
    private static final String API_VERSION_PARAMETER = "v";
    private static final String API_VERSION_1 = "1.0";

    /**
     * Origins allowed to call this API from a browser.
     *
     * Empty by default in the sense that matters: the only entries are the
     * Vite dev server's ports. A deployment that serves the app from another
     * origin sets CORS_ALLOWED_ORIGINS, and one that serves the app behind the
     * same origin as the API sets it to nothing and needs no CORS at all.
     */
    private final String[] allowedOrigins;

    public WebConfig(@Value("${school.cors.allowed-origins}") String[] allowedOrigins) {
        this.allowedOrigins = allowedOrigins;
    }

    @Override
    public void configureApiVersioning(ApiVersionConfigurer configurer) {
        configurer
                .useMediaTypeParameter(ELVEN_API_MEDIA_TYPE, API_VERSION_PARAMETER)
                .addSupportedVersions(API_VERSION_1)
                .setDefaultVersion(API_VERSION_1);
    }

    @Override
    public void configurePathMatch(PathMatchConfigurer configurer) {
        configurer.addPathPrefix("/api", controllerType -> true);
    }

    /**
     * Cross-origin access for a browser that talks to this API directly.
     *
     * This is the fallback, not the intended path. The Vite dev server proxies
     * /api to :8080 so the browser stays on one origin and no CORS is involved
     * - see school-ui/vite.config.ts. It matters when VITE_API_BASE_URL points
     * at an absolute http://localhost:8080/api, which skips that proxy.
     *
     * allowCredentials is on because school-ui sends `withCredentials: true`,
     * and a credentialed request is refused unless the server both names the
     * exact origin - never the "*" wildcard - and says credentials are allowed.
     * That pairing is why the origins are listed rather than globbed.
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        if (allowedOrigins.length == 0) return;

        registry.addMapping("/api/**")
                .allowedOrigins(allowedOrigins)
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(1800);
    }
}
