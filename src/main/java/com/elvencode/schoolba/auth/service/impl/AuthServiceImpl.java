package com.elvencode.schoolba.auth.service.impl;

import com.elvencode.schoolba.auth.dto.LoginResponseDto;
import com.elvencode.schoolba.auth.dto.UserDto;
import com.elvencode.schoolba.auth.dto.request.LoginRequestDto;
import com.elvencode.schoolba.auth.exception.InvalidLoginCredentialsException;
import com.elvencode.schoolba.auth.exception.LoginAuthenticationException;
import com.elvencode.schoolba.auth.jwt.JwtUtil;
import com.elvencode.schoolba.auth.service.IAuthService;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.stereotype.Service;

@Service
public class AuthServiceImpl implements IAuthService {

    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;

    public AuthServiceImpl(AuthenticationManager authenticationManager, JwtUtil jwtUtil) {
        this.authenticationManager = authenticationManager;
        this.jwtUtil = jwtUtil;
    }

    @Override
    public LoginResponseDto login(LoginRequestDto loginRequestDto) {
        Authentication authentication = authenticate(loginRequestDto);
        UserDto user = new UserDto(authentication.getName());

        return new LoginResponseDto(HttpStatus.OK.getReasonPhrase(), user, jwtUtil.generateJwtToken(authentication));
    }

    private Authentication authenticate(LoginRequestDto loginRequestDto) {
        try {
            return authenticationManager.authenticate(
                    UsernamePasswordAuthenticationToken.unauthenticated(
                            loginRequestDto.username(),
                            loginRequestDto.password()
                    )
            );
        } catch (BadCredentialsException exception) {
            throw new InvalidLoginCredentialsException("Invalid username or password", exception);
        } catch (AuthenticationException exception) {
            throw new LoginAuthenticationException("Authentication failed", exception);
        }
    }
}
