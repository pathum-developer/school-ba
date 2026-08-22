package com.elvencode.schoolba.auth.dto;

public sealed interface LoginResponse permits AccessTokenResponse, MfaRequiredResponse {
}
