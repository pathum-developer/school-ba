package com.elvencode.schoolba.school.branch.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.school.branch.entity.Branch;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BranchRepository extends JpaRepository<Branch, UUID> {

    Optional<Branch> findBySchool_IdAndHeadOfficeTrue(UUID schoolId);

    Optional<Branch> findBySchool_IdAndCode(UUID schoolId, String code);

    @EntityGraph(attributePaths = {"school", "contactNoList"})
    Optional<Branch> findDetailedBySchool_IdAndCode(UUID schoolId, String code);

    boolean existsBySchool_IdAndCode(UUID schoolId, String code);

    @EntityGraph(attributePaths = {"school", "contactNoList"})
    List<Branch> findAllBySchool_IdAndActiveTrueOrderByHeadOfficeDescNameAsc(UUID schoolId);

}
