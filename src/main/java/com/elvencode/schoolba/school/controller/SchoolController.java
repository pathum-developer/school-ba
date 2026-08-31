package com.elvencode.schoolba.school.controller;

import com.elvencode.schoolba.school.dto.SchoolProfileDto;
import com.elvencode.schoolba.school.service.ISchoolService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/schools")
public class SchoolController {

    private static final String API_VERSION_1_BASELINE = "1.0+";

    private final ISchoolService schoolService;

    public SchoolController(ISchoolService schoolService) {
        this.schoolService = schoolService;
    }

    @GetMapping(value = {"/profile", "/getProfile"}, version = API_VERSION_1_BASELINE)
    public ResponseEntity<SchoolProfileDto> getProfile() {
        return ResponseEntity.ok(schoolService.getSchoolProfile());
    }
}
