package com.elvencode.schoolba.domainclasses.domainentity;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

import com.elvencode.schoolba.domainclasses.Domain;
import com.elvencode.schoolba.school.branch.entity.Branch;
import com.elvencode.schoolba.school.enums.BranchType;

/**
 * Creates branch rows for tests. Prefer calling this through {@link Domain}.
 *
 * <p>Every column is given a default that satisfies the branch check constraints, so a test sets
 * only the attributes its assertions depend on and leaves the rest alone. The owning school is the
 * one exception: {@link SchoolDomain} links it when the branch is attached to a school, and a test
 * building a standalone branch sets it explicitly.
 */
public final class BranchDomain {

    private BranchDomain() {
    }

    public static Branch createBranch(Consumer<Branch> attributes) {
        Branch branch = new Branch();
        branch.setCode("test-branch");
        branch.setName("Test Branch");
        branch.setBranchType(BranchType.BRANCH);
        branch.setAddress("1 Test Road");
        branch.setHeadOffice(false);
        branch.setActive(true);
        attributes.accept(branch);
        return branch;
    }

    /**
     * Builds one branch per lambda and returns them in a mutable list, which is the shape
     * {@code School.setBranches} expects.
     */
    @SafeVarargs
    public static List<Branch> createBranches(Consumer<Branch>... attributes) {
        List<Branch> branches = new ArrayList<>();
        for (Consumer<Branch> branchAttributes : attributes) {
            branches.add(createBranch(branchAttributes));
        }
        return branches;
    }
}
