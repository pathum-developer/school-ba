package com.elvencode.schoolba.auth.enums;

/**
 * Lifecycle of a login account. Only {@link #ACTIVE} may authenticate.
 *
 * <p>Mirrors {@code ck_identity_status}. Adding a value here without adding it to that
 * check constraint produces a row the database refuses to store.
 */
public enum IdentityStatus {

    /** Access has been issued but no password is set yet. Cannot sign in. */
    PENDING_ACTIVATION,

    /** Usable. The only status that may authenticate. */
    ACTIVE,

    /** Withheld by an administrator, expected to be restored. */
    SUSPENDED,

    /** Withheld automatically after too many failed attempts. See lockedUntil. */
    LOCKED,

    /**
     * Withdrawn for good. Set by trigger when the person behind the account leaves,
     * and never cleared automatically, so re-enrolling or rehiring does not silently
     * restore access.
     */
    DISABLED
}
