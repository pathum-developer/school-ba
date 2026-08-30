package com.elvencode.schoolba.common.constants;

public class ApplicationConstant {

    private ApplicationConstant() {
        throw new AssertionError("Utility class cannot be instantiated.");
    }

    public static final String JWT_TOKEN_HEADER = "Authorization";
    public static final String JWT_TOKEN_PREFIX = "Bearer ";
    public static final String JWT_SECRET_KEY = "JWT_SECRET";
    public static final String JWT_SECRET_DEFAULT_VALUE = "jxgEQeXHuPq8VdbySUGOVVWudQ53YUn4";

}
