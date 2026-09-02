package com.elvencode.schoolba.auth.service;

import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;

public interface IIdentityAuthenticationService {

    AuthenticatedIdentity authenticate(String username, String password);
}
