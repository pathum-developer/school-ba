package com.elvencode.schoolba.auth.service;

import com.elvencode.schoolba.auth.dto.LoginResponseDto;
import com.elvencode.schoolba.auth.dto.request.LoginRequestDto;

public interface IAuthService {

    LoginResponseDto login(LoginRequestDto loginRequestDto);
}
