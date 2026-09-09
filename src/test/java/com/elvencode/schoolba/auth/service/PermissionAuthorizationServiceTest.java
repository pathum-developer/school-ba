package com.elvencode.schoolba.auth.service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.auth.constants.PermissionCode;
import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;
import com.elvencode.schoolba.auth.dto.IdentityGrant;
import com.elvencode.schoolba.auth.enums.IdentityStatus;
import com.elvencode.schoolba.auth.enums.ScopeType;
import com.elvencode.schoolba.school.branch.repository.BranchRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PermissionAuthorizationServiceTest {

    private static final UUID IDENTITY_ID = UUID.fromString("70000000-0000-0000-0000-000000000001");
    private static final UUID SCHOOL_ID = UUID.fromString("20000000-0000-0000-0000-000000000001");
    private static final UUID STAFF_ID = UUID.fromString("60000000-0000-0000-0000-000000000001");
    private static final UUID BRANCH_ID = UUID.fromString("30000000-0000-0000-0000-000000000001");
    private static final UUID OTHER_BRANCH_ID = UUID.fromString("30000000-0000-0000-0000-000000000002");
    private static final String BRANCH_CODE = "rajagiriya";

    @Mock
    private BranchRepository branchRepository;

    private PermissionAuthorizationService permissionAuthorizationService;

    @BeforeEach
    void setUp() {
        permissionAuthorizationService = new PermissionAuthorizationService(branchRepository);
    }

    @Test
    void hasBranchPermissionAllowsPlatformGrantWithoutBranchLookup() {
        Authentication authentication = authentication(List.of(
                new IdentityGrant(PermissionCode.BRANCH_LICENSE_CLASS_READ, ScopeType.PLATFORM, null, null)
        ));

        assertTrue(permissionAuthorizationService.hasBranchPermission(
                authentication,
                SCHOOL_ID,
                BRANCH_CODE,
                PermissionCode.BRANCH_LICENSE_CLASS_READ
        ));
        verifyNoInteractions(branchRepository);
    }

    @Test
    void hasBranchPermissionAllowsMatchingSchoolGrantWithoutBranchLookup() {
        Authentication authentication = authentication(List.of(
                new IdentityGrant(PermissionCode.BRANCH_LICENSE_CLASS_READ, ScopeType.SCHOOL, SCHOOL_ID, null)
        ));

        assertTrue(permissionAuthorizationService.hasBranchPermission(
                authentication,
                SCHOOL_ID,
                BRANCH_CODE,
                PermissionCode.BRANCH_LICENSE_CLASS_READ
        ));
        verifyNoInteractions(branchRepository);
    }

    @Test
    void hasBranchPermissionAllowsMatchingBranchGrant() {
        Authentication authentication = authentication(List.of(
                new IdentityGrant(PermissionCode.BRANCH_LICENSE_CLASS_READ, ScopeType.BRANCH, SCHOOL_ID, BRANCH_ID)
        ));

        when(branchRepository.findIdBySchoolIdAndCode(SCHOOL_ID, BRANCH_CODE)).thenReturn(Optional.of(BRANCH_ID));

        assertTrue(permissionAuthorizationService.hasBranchPermission(
                authentication,
                SCHOOL_ID,
                BRANCH_CODE,
                PermissionCode.BRANCH_LICENSE_CLASS_READ
        ));
        verify(branchRepository).findIdBySchoolIdAndCode(SCHOOL_ID, BRANCH_CODE);
    }

    @Test
    void hasBranchPermissionRejectsDifferentBranchGrant() {
        Authentication authentication = authentication(List.of(
                new IdentityGrant(PermissionCode.BRANCH_LICENSE_CLASS_READ, ScopeType.BRANCH, SCHOOL_ID, OTHER_BRANCH_ID)
        ));

        when(branchRepository.findIdBySchoolIdAndCode(SCHOOL_ID, BRANCH_CODE)).thenReturn(Optional.of(BRANCH_ID));

        assertFalse(permissionAuthorizationService.hasBranchPermission(
                authentication,
                SCHOOL_ID,
                BRANCH_CODE,
                PermissionCode.BRANCH_LICENSE_CLASS_READ
        ));
        verify(branchRepository).findIdBySchoolIdAndCode(SCHOOL_ID, BRANCH_CODE);
    }

    @Test
    void hasBranchPermissionRejectsMissingPermissionWithoutBranchLookup() {
        Authentication authentication = authentication(List.of(
                new IdentityGrant("branch:read", ScopeType.SCHOOL, SCHOOL_ID, null)
        ));

        assertFalse(permissionAuthorizationService.hasBranchPermission(
                authentication,
                SCHOOL_ID,
                BRANCH_CODE,
                PermissionCode.BRANCH_LICENSE_CLASS_READ
        ));
        verifyNoInteractions(branchRepository);
    }

    @Test
    void hasBranchPermissionRejectsUnauthenticatedRequest() {
        assertFalse(permissionAuthorizationService.hasBranchPermission(
                null,
                SCHOOL_ID,
                BRANCH_CODE,
                PermissionCode.BRANCH_LICENSE_CLASS_READ
        ));
        verifyNoInteractions(branchRepository);
    }

    private Authentication authentication(List<IdentityGrant> grantList) {
        AuthenticatedIdentity identity = new AuthenticatedIdentity(
                IDENTITY_ID,
                "elven_super",
                "Elven Super Admin",
                SCHOOL_ID,
                STAFF_ID,
                null,
                IdentityStatus.ACTIVE,
                1,
                grantList
        );
        return UsernamePasswordAuthenticationToken.authenticated(identity, null, identity.getAuthorities());
    }
}
