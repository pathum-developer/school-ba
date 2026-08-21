package com.elvencode.schoolba.school.controller;

import com.elvencode.schoolba.school.dto.SchoolCatalogueResponse;
import com.elvencode.schoolba.school.service.SchoolCatalogueService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/school/catalog")
public class SchoolCatalogueController {

    private final SchoolCatalogueService schoolCatalogueService;

    public SchoolCatalogueController(SchoolCatalogueService schoolCatalogueService) {
        this.schoolCatalogueService = schoolCatalogueService;
    }

    @GetMapping(version = "1.0+")
    public SchoolCatalogueResponse getCatalogue() {
        return schoolCatalogueService.getCatalogue();
    }
}
