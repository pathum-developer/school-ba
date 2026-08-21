package com.elvencode.schoolba.config.web;

import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.web.servlet.config.annotation.ApiVersionConfigurer;
import org.springframework.web.servlet.config.annotation.PathMatchConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    private static final MediaType ELVEN_API_MEDIA_TYPE =
            MediaType.parseMediaType("application/vnd.elven+json");
    private static final String API_VERSION_PARAMETER = "v";
    private static final String API_VERSION_1 = "1.0";

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
}
