package com.elvencode.schoolba.auth.controller;

import com.elvencode.schoolba.auth.dto.LoginResponseDto;
import com.elvencode.schoolba.auth.dto.request.LoginRequestDto;
import com.elvencode.schoolba.auth.service.IAuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/login")
public class AuthController {

    private final IAuthService authService;

    public AuthController(IAuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/public")
    public ResponseEntity<LoginResponseDto> apiLogin(@Valid @RequestBody LoginRequestDto loginRequestDto) {
        return ResponseEntity.ok(authService.login(loginRequestDto));
    }
}
