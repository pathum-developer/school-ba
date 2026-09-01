package com.elvencode.schoolba.school.mapper;

import com.elvencode.schoolba.school.dto.SchoolProfileDto;
import com.elvencode.schoolba.school.entity.School;
import org.springframework.stereotype.Component;

@Component
public class SchoolMapper {

    public SchoolProfileDto toSchoolProfileDto(School school) {
        return new SchoolProfileDto(
                school.getCode(),
                school.getName(),
                school.getShortName(),
                school.getEstablishedYear(),
                school.getHotlineHref(),
                school.getWhatsappHref(),
                school.getEmail(),
                school.getTenantStatus()
        );
    }
}
