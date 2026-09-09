package com.elvencode.schoolba.school.branch.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.school.branch.dto.BranchLicenceClassDto;
import com.elvencode.schoolba.school.branch.entity.Branch;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface BranchRepository extends JpaRepository<Branch, UUID> {

    Optional<Branch> findBySchool_IdAndHeadOfficeTrue(UUID schoolId);

    Optional<Branch> findBySchool_IdAndCode(UUID schoolId, String code);

    @Query("""
            select distinct branch
            from Branch branch
            join fetch branch.school school
            left join fetch branch.contactNoList
            where school.id = :schoolId
                    and branch.code = :code
            """)
    Optional<Branch> findDetailedBySchool_IdAndCode(
            @Param("schoolId") UUID schoolId,
            @Param("code") String code
    );

    @Query("""
            select new com.elvencode.schoolba.school.branch.dto.BranchLicenceClassDto(
                    licenseClass.code,
                    licenseClass.name,
                    branchLicenseClass.priceLkr
            )
            from BranchLicenseClass branchLicenseClass
            join branchLicenseClass.branch branch
            join branch.school school
            join branchLicenseClass.licenseClass licenseClass
            where school.id = :schoolId
                    and branch.code = :branchCode
                    and licenseClass.active = true
            order by licenseClass.displayOrder asc
            """)
    List<BranchLicenceClassDto> findLicenceClassListBySchoolIdAndBranchCode(
            @Param("schoolId") UUID schoolId,
            @Param("branchCode") String branchCode
    );

    @Query("""
            select branch.id
            from Branch branch
            where branch.school.id = :schoolId
                    and branch.code = :branchCode
            """)
    Optional<UUID> findIdBySchoolIdAndCode(
            @Param("schoolId") UUID schoolId,
            @Param("branchCode") String branchCode
    );

    boolean existsBySchool_IdAndCode(UUID schoolId, String code);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("""
            delete from Branch branch
            where branch.school.id = :schoolId
                    and branch.code = :code
            """)
    int deleteBySchoolIdAndCode(
            @Param("schoolId") UUID schoolId,
            @Param("code") String code
    );

    @EntityGraph(attributePaths = {"school", "contactNoList"})
    List<Branch> findAllBySchool_IdAndActiveTrueOrderByHeadOfficeDescNameAsc(UUID schoolId);

}
