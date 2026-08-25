package com.elvencode.schoolba.school.service.impl;

import com.elvencode.schoolba.school.dto.SchoolProfileDto;
import com.elvencode.schoolba.school.entity.School;
import com.elvencode.schoolba.school.mapper.SchoolMapper;
import com.elvencode.schoolba.school.repository.SchoolRepository;
import com.elvencode.schoolba.school.service.ISchoolService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SchoolServiceImpl implements ISchoolService {

    private final SchoolRepository  schoolRepository;
    private final SchoolMapper schoolMapper;

    @Autowired
    public SchoolServiceImpl(SchoolRepository schoolRepository, SchoolMapper schoolMapper) {
        this.schoolRepository = schoolRepository;
        this.schoolMapper = schoolMapper;
    }

    @Override
    public SchoolProfileDto getSchoolProfile() {
        School schoolData = schoolRepository.findByCode("elven");
        return schoolMapper.toSchoolProfileDto(schoolData);
    }
}
