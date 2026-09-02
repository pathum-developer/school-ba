package com.elvencode.schoolba.auth.enums;

/**
 * How wide a role, and therefore a grant made from it, reaches.
 *
 * <p>Mirrors {@code ck_role_scope_type}. Ordered from widest to narrowest, so
 * {@link #compareTo} answers "is this scope at least as wide as that one".
 *
 * <p>Scope is not ownership. A permission ending in {@code -own} covers the signed-in
 * person's own record and is resolved against the login's learner id, never against a
 * scope. See {@code docs/architecture/backend/security-and-permissions.md}.
 */
public enum ScopeType {

    /** The platform itself. Held only by a platform operator, who belongs to no school. */
    PLATFORM,

    /** One whole school, every branch in it included. */
    SCHOOL,

    /** A single branch of one school. */
    BRANCH
}
