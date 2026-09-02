package com.elvencode.schoolba.auth.model;

import java.io.Serial;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

import com.elvencode.schoolba.auth.entity.Identity;
import com.elvencode.schoolba.auth.enums.IdentityStatus;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

/**
 * The signed-in account, as the rest of the application sees it.
 *
 * <p>Carries the tenant and person ids an authorization check needs, so no request has to
 * go back to the database to find out which school the caller belongs to or whose record
 * is their own. The {@link Identity} entity itself is deliberately not the principal: it
 * is mutable, holds the password hash, and would be handed to every {@code @AuthenticationPrincipal}
 * argument in the codebase.
 *
 * <p>Authorities are bare permission codes with the scope stripped off, which makes them
 * usable as a cheap first filter in {@code @PreAuthorize}. They are not sufficient on their
 * own: a branch-scoped {@code learner:read} and a school-wide one look identical as strings.
 * Whether a grant reaches a particular school or branch is answered from {@link #getGrantList()}.
 */
@Getter
public final class AuthenticatedIdentity implements UserDetails {

    @Serial
    private static final long serialVersionUID = 1L;

    private final UUID id;
    private final String username;
    private final String displayName;

    /** Owning school. Null only for a platform operator. */
    private final UUID schoolId;

    /** Set only for a staff login. */
    private final UUID staffId;

    /** Set only for a learner login. What every {@code -own} permission resolves against. */
    private final UUID learnerId;

    private final IdentityStatus status;

    /** Grant-set version at sign-in. A later value in the database means these grants are stale. */
    private final int authorizationVersion;

    private final List<IdentityGrant> grantList;

    private final List<GrantedAuthority> authorityList;

    public AuthenticatedIdentity(Identity identity, List<IdentityGrant> grantList) {
        this.id = identity.getId();
        this.username = identity.getUsername();
        this.displayName = identity.getDisplayName();
        this.schoolId = identity.getSchoolId();
        this.staffId = identity.getStaffId();
        this.learnerId = identity.getLearnerId();
        this.status = identity.getStatus();
        this.authorizationVersion = identity.getAuthorizationVersion();
        this.grantList = List.copyOf(grantList);
        this.authorityList = grantList.stream()
                .map(IdentityGrant::permissionCode)
                .distinct()
                .sorted()
                .<GrantedAuthority>map(SimpleGrantedAuthority::new)
                .toList();
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorityList;
    }

    /**
     * Always null. The hash is verified during sign-in and never travels with the principal,
     * so nothing downstream can leak it into a log line or a response body.
     */
    @Override
    public String getPassword() {
        return null;
    }

    @Override
    public boolean isEnabled() {
        return status == IdentityStatus.ACTIVE;
    }

    /**
     * Always true. Lockout is time-based and was evaluated against {@code locked_until} at
     * sign-in; this principal only exists because that check passed.
     */
    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    /** True when this login belongs to a learner, which is what {@code -own} resolves against. */
    public boolean isLearner() {
        return learnerId != null;
    }

    @Override
    public String toString() {
        return "AuthenticatedIdentity(id=%s, username=%s, schoolId=%s)".formatted(id, username, schoolId);
    }
}
