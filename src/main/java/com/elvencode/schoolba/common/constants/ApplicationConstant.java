package com.elvencode.schoolba.common.constants;

public class ApplicationConstant {

    private ApplicationConstant() {
        throw new AssertionError("Utility class cannot be instantiated.");
    }

    public static final String JWT_HEADER = "Authorization";
    public static final String JWT_TOKEN_PREFIX = "Bearer ";
    public static final String JWT_SECRET_KEY = "JWT_SECRET";
    public static final String JWT_SECRET_DEFAULT_VALUE = "jxgEQeXHuPq8VdbySUGOVVWudQ53YUn4";

    /**
     * Claim names. These are the token contract a client reads as well, so they live here
     * rather than inside the writer, and the reader names them from the same place so the two
     * cannot drift apart.
     */
    public static final String JWT_USERNAME_CLAIM = "username";
    public static final String JWT_DISPLAY_NAME_CLAIM = "displayName";
    public static final String JWT_SCHOOL_ID_CLAIM = "schoolId";
    public static final String JWT_STAFF_ID_CLAIM = "staffId";
    public static final String JWT_LEARNER_ID_CLAIM = "learnerId";
    public static final String JWT_AUTHORIZATION_VERSION_CLAIM = "authorizationVersion";
    public static final String JWT_GRANT_LIST_CLAIM = "grantList";

    /** Keys within one entry of the grant list claim. */
    public static final String JWT_GRANT_SCOPE_TYPE = "scopeType";
    public static final String JWT_GRANT_SCHOOL_ID = "schoolId";
    public static final String JWT_GRANT_BRANCH_ID = "branchId";
    public static final String JWT_GRANT_PERMISSION_CODE_LIST = "permissionCodeList";

}
