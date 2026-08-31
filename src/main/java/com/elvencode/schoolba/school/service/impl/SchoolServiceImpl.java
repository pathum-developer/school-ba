package com.elvencode.schoolba.school.service.impl;

import com.elvencode.schoolba.common.exception.ResourceNotFoundException;
import com.elvencode.schoolba.school.dto.SchoolProfileDto;
import com.elvencode.schoolba.school.entity.School;
import com.elvencode.schoolba.school.mapper.SchoolMapper;
import com.elvencode.schoolba.school.repository.SchoolRepository;
import com.elvencode.schoolba.school.service.ISchoolService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class SchoolServiceImpl implements ISchoolService {

    private final SchoolRepository schoolRepository;
    private final SchoolMapper schoolMapper;
    private final String schoolProfileCode;

    public SchoolServiceImpl(
            SchoolRepository schoolRepository,
            SchoolMapper schoolMapper,
            @Value("${school.profile.code}") String schoolProfileCode
    ) {
        this.schoolRepository = schoolRepository;
        this.schoolMapper = schoolMapper;
        this.schoolProfileCode = schoolProfileCode;
    }

    @Override
    public SchoolProfileDto getSchoolProfile() {
        School school = schoolRepository.findByCode(schoolProfileCode)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "School profile not found for code: " + schoolProfileCode
                ));
        return schoolMapper.toSchoolProfileDto(school);
    }
}
