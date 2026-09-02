package com.elvencode.schoolba.auth.service.impl;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;
import com.elvencode.schoolba.auth.dto.IdentityGrant;
import com.elvencode.schoolba.auth.entity.Identity;
import com.elvencode.schoolba.auth.enums.IdentityStatus;
import com.elvencode.schoolba.auth.enums.ScopeType;
import com.elvencode.schoolba.auth.repository.IdentityRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class IdentityAuthenticationServiceImplTest {

    private static final UUID IDENTITY_ID = UUID.fromString("70000000-0000-0000-0000-000000000001");
    private static final UUID SCHOOL_ID = UUID.fromString("20000000-0000-0000-0000-000000000001");
    private static final String USERNAME = "elven_super";
    private static final String RAW_PASSWORD = "ElvenSuper@123";
    private static final String PASSWORD_HASH = "$2a$10$storedHash";

    @Mock
    private IdentityRepository identityRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    private IdentityAuthenticationServiceImpl identityAuthenticationService;

    @BeforeEach
    void setUp() {
        when(passwordEncoder.encode(anyString())).thenReturn("$2a$10$absentAccountHash");
        identityAuthenticationService = new IdentityAuthenticationServiceImpl(identityRepository, passwordEncoder);
    }

    @Test
    void authenticateReturnsPrincipalCarryingEveryGrantAsAnAuthority() {
        when(identityRepository.findByUsername(USERNAME)).thenReturn(Optional.of(activeIdentity()));
        when(passwordEncoder.matches(RAW_PASSWORD, PASSWORD_HASH)).thenReturn(true);
        when(identityRepository.findGrantListByIdentityId(IDENTITY_ID)).thenReturn(List.of(
                new IdentityGrant("branch:read", ScopeType.SCHOOL, SCHOOL_ID, null),
                new IdentityGrant("branch:create", ScopeType.SCHOOL, SCHOOL_ID, null)
        ));

        AuthenticatedIdentity principal = identityAuthenticationService.authenticate(USERNAME, RAW_PASSWORD);

        assertEquals(IDENTITY_ID, principal.getId());
        assertEquals(USERNAME, principal.getUsername());
        assertEquals(SCHOOL_ID, principal.getSchoolId());
        assertEquals(
                List.of("branch:create", "branch:read"),
                principal.getAuthorities().stream().map(GrantedAuthority::getAuthority).toList()
        );
        assertEquals(
                new IdentityGrant("branch:read", ScopeType.SCHOOL, SCHOOL_ID, null),
                principal.getGrantList().getFirst()
        );
    }

    @Test
    void authenticateFoldsTheEnteredUsernameToTheStoredLowerCaseForm() {
        when(identityRepository.findByUsername(USERNAME)).thenReturn(Optional.of(activeIdentity()));
        when(passwordEncoder.matches(RAW_PASSWORD, PASSWORD_HASH)).thenReturn(true);
        when(identityRepository.findGrantListByIdentityId(IDENTITY_ID)).thenReturn(List.of());

        AuthenticatedIdentity principal = identityAuthenticationService.authenticate("  ELVEN_Super ", RAW_PASSWORD);

        assertEquals(USERNAME, principal.getUsername());
        assertTrue(principal.getAuthorities().isEmpty());
    }

    @Test
    void authenticateRejectsAnUnknownUsernameWithoutRevealingThatItIsUnknown() {
        when(identityRepository.findByUsername("ghost")).thenReturn(Optional.empty());

        assertThrows(
                BadCredentialsException.class,
                () -> identityAuthenticationService.authenticate("ghost", RAW_PASSWORD)
        );

        // Still hashes something, so an unknown username costs the same time as a known one.
        verify(passwordEncoder).matches(eq(RAW_PASSWORD), anyString());
    }

    @Test
    void authenticateRejectsAWrongPassword() {
        when(identityRepository.findByUsername(USERNAME)).thenReturn(Optional.of(activeIdentity()));
        when(passwordEncoder.matches(any(), eq(PASSWORD_HASH))).thenReturn(false);

        assertThrows(
                BadCredentialsException.class,
                () -> identityAuthenticationService.authenticate(USERNAME, "wrong")
        );
        verify(identityRepository, never()).findGrantListByIdentityId(any());
    }

    @Test
    void authenticateRejectsAnAccountThatHasNoPasswordYet() {
        Identity identity = activeIdentity();
        identity.setPasswordHash(null);
        identity.setStatus(IdentityStatus.PENDING_ACTIVATION);
        when(identityRepository.findByUsername(USERNAME)).thenReturn(Optional.of(identity));

        // Not DisabledException: someone guessing passwords must not learn that the account
        // exists and is sitting there waiting to be activated.
        assertThrows(
                BadCredentialsException.class,
                () -> identityAuthenticationService.authenticate(USERNAME, RAW_PASSWORD)
        );
    }

    @Test
    void authenticateRejectsALockedOutAccountEvenWhenThePasswordIsRight() {
        Identity identity = activeIdentity();
        identity.setLockedUntil(LocalDateTime.now().plusMinutes(15));
        when(identityRepository.findByUsername(USERNAME)).thenReturn(Optional.of(identity));
        when(passwordEncoder.matches(RAW_PASSWORD, PASSWORD_HASH)).thenReturn(true);

        assertThrows(
                LockedException.class,
                () -> identityAuthenticationService.authenticate(USERNAME, RAW_PASSWORD)
        );
    }

    @Test
    void authenticateRejectsAnAccountThatIsNotActive() {
        Identity identity = activeIdentity();
        identity.setStatus(IdentityStatus.SUSPENDED);
        when(identityRepository.findByUsername(USERNAME)).thenReturn(Optional.of(identity));
        when(passwordEncoder.matches(RAW_PASSWORD, PASSWORD_HASH)).thenReturn(true);

        assertThrows(
                DisabledException.class,
                () -> identityAuthenticationService.authenticate(USERNAME, RAW_PASSWORD)
        );
    }

    @Test
    void authenticateRejectsABlankPasswordWithoutTouchingTheIdentityStore() {
        assertThrows(
                BadCredentialsException.class,
                () -> identityAuthenticationService.authenticate(USERNAME, "   ")
        );
        verify(identityRepository, never()).findByUsername(any());
    }

    private Identity activeIdentity() {
        Identity identity = new Identity();
        identity.setId(IDENTITY_ID);
        identity.setSchoolId(SCHOOL_ID);
        identity.setStaffId(UUID.fromString("60000000-0000-0000-0000-000000000001"));
        identity.setUsername(USERNAME);
        identity.setDisplayName("Elven Super Admin");
        identity.setPasswordHash(PASSWORD_HASH);
        identity.setStatus(IdentityStatus.ACTIVE);
        return identity;
    }

}
