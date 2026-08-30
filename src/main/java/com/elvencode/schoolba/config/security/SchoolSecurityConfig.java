package com.elvencode.schoolba.config.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.util.matcher.RegexRequestMatcher;

import static org.springframework.security.config.Customizer.withDefaults;

@Configuration
@EnableWebSecurity
public class SchoolSecurityConfig {

    @Bean
    SecurityFilterChain customSecurityFilterChain(HttpSecurity http) throws Exception {
        return http.csrf(csrfConfigurer -> csrfConfigurer.disable())
                .authorizeHttpRequests(requests -> requests
                        .requestMatchers(RegexRequestMatcher.regexMatcher(".*public$")).permitAll()
                        .anyRequest().authenticated())
                .formLogin(flc -> flc.disable())
                .httpBasic(withDefaults())
                .build();
    }
}
