package com.elvencode.schoolba.auth.dto;

public record LoginResponseDto(
        String status,
        UserDto user,
        String token
) {
}
