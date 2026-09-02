package com.elvencode.schoolba.config.security;

import com.elvencode.schoolba.config.security.filter.JwtTokenValidatorFilter;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
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
    public UserDetailsService userDetailsService(PasswordEncoder passwordEncoder) {
        var user = User.builder()
                .username("ElvenUser")
                .password(passwordEncoder.encode("ElvenPassword"))
                .roles("USER")
                .build();

        var admin = User.builder()
                .username("ElvenAdminUser")
                .password(passwordEncoder.encode("ElvenAdminPassword"))
                .roles("ADMIN")
                .build();

        return new InMemoryUserDetailsManager(user, admin);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * Real accounts are tried first, and the in-memory pair only if no identity row matched.
     * {@code ProviderManager} stops the chain on an {@code AccountStatusException}, so a
     * suspended or locked account is refused outright rather than being offered to the
     * fallback provider.
     *
     * <p>The in-memory provider is transitional. It exists only to keep the seeded demo
     * logins working and should be dropped once every caller signs in against m_identity.
     */
    @Bean
    public AuthenticationManager authenticationManager(
            SchoolIdentityAuthenticationProvider schoolIdentityAuthenticationProvider,
            UserDetailsService userDetailsService,
            PasswordEncoder passwordEncoder) {
        DaoAuthenticationProvider inMemoryAuthenticationProvider = new DaoAuthenticationProvider(userDetailsService);
        inMemoryAuthenticationProvider.setPasswordEncoder(passwordEncoder);
        return new ProviderManager(schoolIdentityAuthenticationProvider, inMemoryAuthenticationProvider);
    }
}
