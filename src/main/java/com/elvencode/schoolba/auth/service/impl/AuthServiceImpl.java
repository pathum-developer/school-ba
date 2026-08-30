package com.elvencode.schoolba.auth.service.impl;

import com.elvencode.schoolba.auth.dto.LoginResponseDto;
import com.elvencode.schoolba.auth.dto.UserDto;
import com.elvencode.schoolba.auth.dto.request.LoginRequestDto;
import com.elvencode.schoolba.auth.service.IAuthService;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AuthServiceImpl implements IAuthService {

    private static final String ROLE_PREFIX = "ROLE_";

    private final AuthenticationManager authenticationManager;

    public AuthServiceImpl(AuthenticationManager authenticationManager) {
        this.authenticationManager = authenticationManager;
    }

    @Override
    public LoginResponseDto login(LoginRequestDto loginRequestDto) {
        Authentication authentication = authenticationManager.authenticate(
                UsernamePasswordAuthenticationToken.unauthenticated(
                        loginRequestDto.username(),
                        loginRequestDto.password()
                )
        );

        UserDto user = new UserDto(authentication.getName(), roleList(authentication));
        return new LoginResponseDto(HttpStatus.OK.getReasonPhrase(), user, null);
    }

    private List<String> roleList(Authentication authentication) {
        return authentication.getAuthorities()
                .stream()
                .map(GrantedAuthority::getAuthority)
                .filter(authority -> authority.startsWith(ROLE_PREFIX))
                .map(this::removeRolePrefix)
                .toList();
    }

    private String removeRolePrefix(String authority) {
        if (authority.startsWith(ROLE_PREFIX)) {
            return authority.substring(ROLE_PREFIX.length());
        }
        return authority;
    }
}
