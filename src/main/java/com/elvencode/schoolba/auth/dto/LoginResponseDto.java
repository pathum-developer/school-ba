package com.elvencode.schoolba.auth.dto;

public record LoginResponseDto(
        String message,
        UserDto user,
        String token
) {
}
