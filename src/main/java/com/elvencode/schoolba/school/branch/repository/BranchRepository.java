package com.elvencode.schoolba.school.branch.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.school.branch.entity.Branch;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface BranchRepository extends JpaRepository<Branch, UUID> {

    @EntityGraph(attributePaths = "school")
    Optional<Branch> findByIdAndActiveTrue(UUID id);

    @EntityGraph(attributePaths = "school")
    Optional<Branch> findBySchool_IdAndCode(UUID schoolId, String code);

    @Query("""
            SELECT branch
            FROM Branch branch
            JOIN FETCH branch.school school
            WHERE school.code = :schoolCode
              AND branch.code = :code
              AND branch.active = true
            """)
    Optional<Branch> findBySchool_CodeAndCodeAndActiveTrue(
            @Param("schoolCode") String schoolCode,
            @Param("code") String code
    );

    Optional<Branch> findBySchool_IdAndHeadOfficeTrue(UUID schoolId);

    @EntityGraph(attributePaths = "school")
    Optional<Branch> findBySchool_IdAndHeadOfficeTrueAndActiveTrue(UUID schoolId);

    boolean existsBySchool_IdAndCode(UUID schoolId, String code);

    @EntityGraph(attributePaths = "school")
    List<Branch> findAllBySchool_IdAndActiveTrueOrderByHeadOfficeDescNameAsc(UUID schoolId);

    @Query("""
            SELECT branch
            FROM Branch branch
            JOIN FETCH branch.school school
            WHERE school.code = :schoolCode
              AND branch.active = true
            ORDER BY branch.headOffice DESC, branch.name ASC
            """)
    List<Branch> findAllBySchool_CodeAndActiveTrueOrderByHeadOfficeDescNameAsc(
            @Param("schoolCode") String schoolCode
    );
}
