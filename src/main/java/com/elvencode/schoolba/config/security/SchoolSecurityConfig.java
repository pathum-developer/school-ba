package com.elvencode.schoolba.config.security;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

import java.util.List;

import static org.springframework.security.config.Customizer.withDefaults;

@Configuration
@EnableWebSecurity
public class SchoolSecurityConfig {

    private final List<String> publicPathList;
    private final List<String> securedPathList;

    public SchoolSecurityConfig(@Qualifier("publicPaths") List<String> publicPathList,
                                @Qualifier("securedPaths") List<String> securedPathList) {
        this.publicPathList = publicPathList;
        this.securedPathList = securedPathList;
    }

    @Bean
    SecurityFilterChain customSecurityFilterChain(HttpSecurity http) throws Exception {
        return http.csrf(csrfConfigurer -> csrfConfigurer.disable())
                .authorizeHttpRequests(requests -> {
                    publicPathList.forEach(path -> requests.requestMatchers(path).permitAll());
                    securedPathList.forEach(path -> requests.requestMatchers(path).authenticated());
                    requests.anyRequest().denyAll();
                })
                .formLogin(flc -> flc.disable())
                .httpBasic(withDefaults())
                .build();
    }
}
