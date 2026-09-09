package com.elvencode.schoolba.auth.service;

import java.util.UUID;

import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;
import com.elvencode.schoolba.auth.dto.IdentityGrant;
import com.elvencode.schoolba.auth.enums.ScopeType;
import com.elvencode.schoolba.school.branch.repository.BranchRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service("permissionAuthorizationService")
@Transactional(readOnly = true)
public class PermissionAuthorizationService {

    private final BranchRepository branchRepository;

    public PermissionAuthorizationService(BranchRepository branchRepository) {
        this.branchRepository = branchRepository;
    }

    public boolean hasBranchPermission(
            Authentication authentication,
            UUID schoolId,
            String branchCode,
            String permissionCode
    ) {
        if (!(authentication != null
                && authentication.isAuthenticated()
                && authentication.getPrincipal() instanceof AuthenticatedIdentity identity)
                || schoolId == null
                || branchCode == null
                || branchCode.isBlank()
                || permissionCode == null
                || permissionCode.isBlank()) {
            return false;
        }

        String requiredBranchCode = branchCode.trim();
        if (!holdsPermission(identity, permissionCode)) {
            return false;
        }
        if (hasPlatformOrSchoolGrant(identity, schoolId, permissionCode)) {
            return true;
        }

        return branchRepository.findIdBySchoolIdAndCode(schoolId, requiredBranchCode)
                .filter(branchId -> hasBranchGrant(identity, schoolId, branchId, permissionCode))
                .isPresent();
    }

    private boolean holdsPermission(AuthenticatedIdentity identity, String permissionCode) {
        return identity.getGrantList().stream()
                .anyMatch(grant -> permissionCode.equals(grant.permissionCode()));
    }

    private boolean hasPlatformOrSchoolGrant(
            AuthenticatedIdentity identity,
            UUID schoolId,
            String permissionCode
    ) {
        return identity.getGrantList().stream()
                .anyMatch(grant -> appliesAtPlatformOrSchool(grant, schoolId, permissionCode));
    }

    private boolean hasBranchGrant(
            AuthenticatedIdentity identity,
            UUID schoolId,
            UUID branchId,
            String permissionCode
    ) {
        return identity.getGrantList().stream()
                .anyMatch(grant -> appliesAtBranch(grant, schoolId, branchId, permissionCode));
    }

    private boolean appliesAtPlatformOrSchool(IdentityGrant grant, UUID schoolId, String permissionCode) {
        if (!permissionCode.equals(grant.permissionCode())) {
            return false;
        }
        return switch (grant.scopeType()) {
            case PLATFORM -> true;
            case SCHOOL -> schoolId.equals(grant.schoolId());
            case BRANCH -> false;
        };
    }

    private boolean appliesAtBranch(
            IdentityGrant grant,
            UUID schoolId,
            UUID branchId,
            String permissionCode
    ) {
        return permissionCode.equals(grant.permissionCode())
                && grant.scopeType() == ScopeType.BRANCH
                && schoolId.equals(grant.schoolId())
                && branchId.equals(grant.branchId());
    }
}
