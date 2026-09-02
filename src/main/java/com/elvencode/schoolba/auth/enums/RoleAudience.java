package com.elvencode.schoolba.auth.enums;

/**
 * Which kind of person a role may be given to.
 *
 * <p>Mirrors {@code ck_role_assignable_to} and {@code ck_identity_role_assignment_assignable_to}.
 * Adding a value here without adding it to both check constraints produces a row the database
 * refuses to store.
 *
 * <p>Kept separate from the login's own staff or learner link because a role is written before
 * anyone holds it: the role catalogue says who a grant may be made to, and the grant then records
 * which of them it was actually made to.
 */
public enum RoleAudience {

    /** Staff of a school or of one of its branches. */
    STAFF,

    /** Learners. Never branch scoped, per {@code ck_role_learner_not_branch}. */
    LEARNER
}
