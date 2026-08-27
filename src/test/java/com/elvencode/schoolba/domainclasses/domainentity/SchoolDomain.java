package com.elvencode.schoolba.domainclasses.domainentity;

import java.util.function.Consumer;

import com.elvencode.schoolba.domainclasses.Domain;
import com.elvencode.schoolba.school.entity.School;

/**
 * Creates school rows for tests. Prefer calling this through {@link Domain}.
 *
 * <p>Every default satisfies the school check constraints. After the attributes have been applied,
 * each branch that was added to the school is pointed back at it, because {@code School.branches}
 * is the inverse side of the association and would otherwise leave {@code branch.school_id} null.
 *
 * <p>Note that the school table is a singleton: {@code uk_school_singleton} together with
 * {@code ck_school_singleton_key_true} allows exactly one row, so a test may save at most one
 * school.
 */
public final class SchoolDomain {

    private SchoolDomain() {
    }

    public static School createSchool(Consumer<School> attributes) {
        School school = new School();
        school.setCode("test-school");
        school.setName("Test Driving School");
        school.setShortName("Test");
        school.setEstablishedYear((short) 2000);
        school.setHotlineHref("tel:+94110000000");
        school.setWhatsappHref("https://wa.me/94110000000");
        school.setEmail("test@example.com");
        school.setSingletonKey(true);

        attributes.accept(school);

        school.getBranches().forEach(branch -> branch.setSchool(school));
        return school;
    }
}
