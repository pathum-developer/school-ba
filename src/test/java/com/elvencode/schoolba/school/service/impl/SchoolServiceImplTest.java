package com.elvencode.schoolba.school.service.impl;

import com.elvencode.schoolba.common.exception.ResourceNotFoundException;
import com.elvencode.schoolba.school.dto.SchoolProfileDto;
import com.elvencode.schoolba.school.entity.School;
import com.elvencode.schoolba.school.enums.TenantStatus;
import com.elvencode.schoolba.school.mapper.SchoolMapper;
import com.elvencode.schoolba.school.repository.SchoolRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SchoolServiceImplTest {

    private static final String SCHOOL_PROFILE_CODE = "elven";

    @Mock
    private SchoolRepository schoolRepository;

    @Mock
    private SchoolMapper schoolMapper;

    @Test
    void getSchoolProfileReturnsConfiguredSchoolProfile() {
        SchoolServiceImpl schoolService = new SchoolServiceImpl(schoolRepository, schoolMapper, SCHOOL_PROFILE_CODE);
        School school = new School();
        SchoolProfileDto expectedProfile = new SchoolProfileDto(
                SCHOOL_PROFILE_CODE,
                "Elven Driving School",
                "Elven",
                (short) 2020,
                "tel:+94770000000",
                "https://wa.me/94770000000",
                "hello@elvendriving.lk",
                TenantStatus.ACTIVE
        );

        when(schoolRepository.findByCode(SCHOOL_PROFILE_CODE)).thenReturn(Optional.of(school));
        when(schoolMapper.toSchoolProfileDto(school)).thenReturn(expectedProfile);

        SchoolProfileDto actualProfile = schoolService.getSchoolProfile();

        assertSame(expectedProfile, actualProfile);
        verify(schoolRepository).findByCode(SCHOOL_PROFILE_CODE);
        verify(schoolMapper).toSchoolProfileDto(school);
    }

    @Test
    void getSchoolProfileThrowsWhenConfiguredSchoolDoesNotExist() {
        SchoolServiceImpl schoolService = new SchoolServiceImpl(schoolRepository, schoolMapper, SCHOOL_PROFILE_CODE);
        when(schoolRepository.findByCode(SCHOOL_PROFILE_CODE)).thenReturn(Optional.empty());

        ResourceNotFoundException exception = assertThrows(
                ResourceNotFoundException.class,
                schoolService::getSchoolProfile
        );

        assertEquals("School profile not found for code: " + SCHOOL_PROFILE_CODE, exception.getMessage());
        verify(schoolMapper, never()).toSchoolProfileDto(any());
    }
}
