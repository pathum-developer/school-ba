package com.elvencode.schoolba.school.controller;

import com.elvencode.schoolba.school.dto.SchoolProfileResponse;
import com.elvencode.schoolba.school.service.SchoolProfileService;
import org.springframework.web.bind.annotation.*;

import javax.lang.model.util.Elements;

@RestController
@RequestMapping("/school/profile")
@CrossOrigin(origins = "http://localhost:5173")
public class SchoolProfileController {

    private final SchoolProfileService schoolProfileService;

    public SchoolProfileController(SchoolProfileService schoolProfileService) {
        this.schoolProfileService = schoolProfileService;
    }
    //     ToDo
    @GetMapping
    public SchoolProfileResponse getProfile() {
        return schoolProfileService.getProfile();
    }

//    @RequestMapping(path = "/school/profile", method = {RequestMethod.GET, RequestMethod.POST}
//   ,consumes = MediaType.APPLICATION_JSON_VALUE,produces= MediaType.APPLICATION_JSON_VALUE
//    )
//    public SchoolProfileResponse getProfile() {
//        return schoolProfileService.getProfile();
//    }

}
