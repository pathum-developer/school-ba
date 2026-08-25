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

    /**
     * What a course is, everywhere it is taught.
     *
     * Deliberately carries no price: what a course costs is a property of the
     * branch teaching it, not of the course, so it lives on
     * {@link BranchOfferResponse}. No single number is true across branches.
     */
    public record CourseResponse(
            String id,
            String licenceClass,
            List<String> dmtClasses,
            int lessons,
            int weeks,
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

    /**
     * A branch, and the courses it actually teaches.
     *
     * {@code offers} replaces a plain list of licence classes: it says both
     * what is taught and what it costs there, which is the pair the site needs
     * to render a branch's prices. A course absent from {@code offers} is not
     * taught at that branch.
     */
    public record BranchResponse(
            String id,
            String kind,
            String phone,
            boolean primary,
            List<BranchOfferResponse> offers,
            String mapsQuery
    ) {
    }

    /** One course taught at one branch, at that branch's price. */
    public record BranchOfferResponse(String courseId, int priceLkr) {
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
