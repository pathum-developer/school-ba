package com.elvencode.schoolba.school.repository;

import com.elvencode.schoolba.school.entity.School;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface SchoolRepository extends JpaRepository<School, UUID> {
    School findByCode(String code);
}
