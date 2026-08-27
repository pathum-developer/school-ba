package com.elvencode.schoolba.domainclasses;

import java.util.List;
import java.util.function.Consumer;

import com.elvencode.schoolba.domainclasses.domainentity.BranchDomain;
import com.elvencode.schoolba.domainclasses.domainentity.SchoolDomain;
import com.elvencode.schoolba.school.branch.entity.Branch;
import com.elvencode.schoolba.school.entity.School;

/**
 * Single entry point for building test data.
 *
 * <p>Each method returns an entity already populated with valid defaults for every column, then
 * hands it to the supplied lambda. A test therefore sets only the attributes it cares about and
 * never has to fill in the rest of the table:
 *
 * <pre>
 * Branch branch = Domain.createBranch(branchData -&gt; branchData.setCode("nawala"));
 * </pre>
 *
 * <p>Children are created by nesting the calls. Use {@code createBranches} with
 * {@code setBranches} to attach a whole list at once:
 *
 * <pre>
 * School school = Domain.createSchool(schoolData -&gt; {
 *     schoolData.setCode("elven");
 *     schoolData.setBranches(Domain.createBranches(
 *             branchData -&gt; {
 *                 branchData.setCode("ra-rathnapura");
 *                 branchData.setName("Rathnapura Branch");
 *             },
 *             branchData -&gt; branchData.setCode("nawala")
 *     ));
 * });
 *
 * schoolRepository.saveAndFlush(school);
 * </pre>
 *
 * <p>Adding to the existing collection works too, and is the better fit when branches are appended
 * one at a time: {@code schoolData.getBranches().add(Domain.createBranch(...))}.
 *
 * <p>Saving the school saves its branches, because {@code School.branches} cascades. Entities are
 * only built and linked here; persisting them stays in the test, so it is always obvious what a
 * test writes to the database.
 *
 * <p>To cover another table, add a sibling class following the shape of {@link SchoolDomain} and
 * expose it here.
 */
public final class Domain {

    private Domain() {
    }

    public static School createSchool(Consumer<School> attributes) {
        return SchoolDomain.createSchool(attributes);
    }

    public static School createSchool() {
        return SchoolDomain.createSchool(school -> {
        });
    }

    public static Branch createBranch(Consumer<Branch> attributes) {
        return BranchDomain.createBranch(attributes);
    }

    public static Branch createBranch() {
        return BranchDomain.createBranch(branch -> {
        });
    }

    @SafeVarargs
    public static List<Branch> createBranches(Consumer<Branch>... attributes) {
        return BranchDomain.createBranches(attributes);
    }
}
