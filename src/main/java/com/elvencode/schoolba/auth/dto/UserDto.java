package com.elvencode.schoolba.auth.dto;

import java.util.List;

public record UserDto(
        String username,
        List<String> roleList
) {
}
