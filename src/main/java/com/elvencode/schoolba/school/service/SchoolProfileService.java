package com.elvencode.schoolba.school.service;

import com.elvencode.schoolba.school.dto.SchoolProfileResponse;
import org.springframework.stereotype.Service;

@Service
public class SchoolProfileService {

    public SchoolProfileResponse getProfile() {
        return new SchoolProfileResponse(
                "Elven Driving School",
                "Elven",
                "077 123 4567",
                "tel:+94771234567",
                "https://wa.me/94771234567",
                "hello@elvendriving.lk",
                1950
        );
    }
}
