package com.elvencode.schoolba.school.branch.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.school.branch.entity.Branch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BranchRepository extends JpaRepository<Branch, UUID> {

    Optional<Branch> findByIdAndActiveTrue(UUID id);

    Optional<Branch> findBySchoolIdAndCode(UUID schoolId, String code);

    Optional<Branch> findBySchoolCodeAndCodeAndActiveTrue(String schoolCode, String code);

    Optional<Branch> findBySchoolIdAndHeadOfficeTrueAndActiveTrue(UUID schoolId);

    boolean existsBySchoolIdAndCode(UUID schoolId, String code);

    List<Branch> findAllBySchoolIdAndActiveTrueOrderByHeadOfficeDescNameAsc(UUID schoolId);

    List<Branch> findAllBySchoolCodeAndActiveTrueOrderByHeadOfficeDescNameAsc(String schoolCode);
}
