package com.elvencode.schoolba.config.security;

import com.elvencode.schoolba.config.security.filter.JwtTokenValidatorFilter;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.authentication.www.BasicAuthenticationFilter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.springframework.security.config.Customizer.withDefaults;

@Configuration
@EnableWebSecurity
public class SchoolSecurityConfig {

    private final List<String> publicPathList;
    private final List<String> securedPathList;
    private final String[] allowedOriginList;

    public SchoolSecurityConfig(@Qualifier("publicPaths") List<String> publicPathList,
                                @Qualifier("securedPaths") List<String> securedPathList,
                                @Value("${school.cors.allowed-origins}") String[] allowedOriginList) {
        this.publicPathList = publicPathList;
        this.securedPathList = securedPathList;
        this.allowedOriginList = allowedOriginList;
    }

    @Bean
    SecurityFilterChain customSecurityFilterChain(HttpSecurity http,
                                                  CorsConfigurationSource corsConfigurationSource,
                                                  JwtTokenValidatorFilter jwtTokenValidatorFilter) throws Exception {
        return http.csrf(csrfConfigurer -> csrfConfigurer.disable())
                .cors(corsConfigurer -> corsConfigurer.configurationSource(corsConfigurationSource))
                .addFilterBefore(jwtTokenValidatorFilter, BasicAuthenticationFilter.class)
                .authorizeHttpRequests(requests -> {
                    publicPathList.forEach(path -> requests.requestMatchers(path).permitAll());
                    securedPathList.forEach(path -> requests.requestMatchers(path).authenticated());
                    requests.anyRequest().denyAll();
                })
                .formLogin(flc -> flc.disable())
                .httpBasic(withDefaults())
                .build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(Arrays.asList(allowedOriginList));
        config.setAllowedMethods(Collections.singletonList("*"));
        config.setAllowedHeaders(Collections.singletonList("*"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * Resolves every login against m_identity through {@link SchoolIdentityAuthenticationProvider}.
     *
     * <p>Deliberately the only provider in the chain. An in-memory pair sat beside it while the
     * database-backed flow was being built, and keeping it would leave two sources of truth for
     * who may sign in, one of them a password committed to this repository.
     *
     * <p>No {@code UserDetailsService} bean is declared for the same reason. Spring Security would
     * wrap one in a {@code DaoAuthenticationProvider} for the global {@code AuthenticationManager},
     * then log that it is being ignored because a provider bean already configures that manager.
     */
    @Bean
    public AuthenticationManager authenticationManager(
            SchoolIdentityAuthenticationProvider schoolIdentityAuthenticationProvider) {
        return new ProviderManager(schoolIdentityAuthenticationProvider);
    }
}
