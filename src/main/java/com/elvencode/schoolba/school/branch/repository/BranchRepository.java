package com.elvencode.schoolba.school.branch.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

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

    @Query(
            value = """
                    select branch.*
                    from m_branch branch
                    join m_school school on school.id = branch.school_id
                    where school.id = :schoolId
                            and branch.code = :code
                    """,
            nativeQuery = true
    )
    Optional<Branch> findDetailedBySchool_IdAndCodeUsingNativeQuery(
            @Param("schoolId") UUID schoolId,
            @Param("code") String code
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
