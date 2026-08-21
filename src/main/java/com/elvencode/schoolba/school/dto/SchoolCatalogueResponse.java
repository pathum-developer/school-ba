package com.elvencode.schoolba.school.dto;

import java.util.List;

public record SchoolCatalogueResponse(
        List<String> licenceClasses,
        List<StatResponse> stats,
        List<CourseResponse> courses,
        List<TrainingPackageResponse> packages,
        List<JourneyStepResponse> journey,
        List<BranchResponse> branches,
        List<LearningResourceResponse> resources,
        List<TestimonialResponse> testimonials,
        List<FaqResponse> faqs
) {

    public record StatResponse(String id, String value) {
    }

    public record CourseResponse(
            String id,
            String licenceClass,
            List<String> dmtClasses,
            int lessons,
            int weeks,
            int priceLkr,
            String transmission,
            boolean popular
    ) {
    }

    public record TrainingPackageResponse(
            String id,
            int priceLkr,
            int lessons,
            boolean popular
    ) {
    }

    public record JourneyStepResponse(String id) {
    }

    public record BranchResponse(
            String id,
            String kind,
            String phone,
            List<String> teaches,
            String mapsQuery
    ) {
    }

    public record LearningResourceResponse(String id, String kind) {
    }

    public record TestimonialResponse(
            String id,
            String name,
            String initials,
            String branchId,
            double rating
    ) {
    }

    public record FaqResponse(String id) {
    }
}
