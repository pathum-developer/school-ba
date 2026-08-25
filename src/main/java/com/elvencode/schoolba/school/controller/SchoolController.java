package com.elvencode.schoolba.school.controller;

import com.elvencode.schoolba.school.dto.SchoolProfileDto;
import com.elvencode.schoolba.school.service.ISchoolService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/schools")
public class SchoolController {

    private final ISchoolService schoolService;

    @Autowired
    public SchoolController(ISchoolService schoolService) {
        this.schoolService = schoolService;
    }

    @GetMapping(value="getProfile")
    public ResponseEntity<SchoolProfileDto> getProfile() {
        return ResponseEntity.ok().body(schoolService.getSchoolProfile());
    }
}
