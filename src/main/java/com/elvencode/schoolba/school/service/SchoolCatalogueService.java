package com.elvencode.schoolba.school.service;

import com.elvencode.schoolba.school.dto.SchoolCatalogueResponse;
import com.elvencode.schoolba.school.dto.SchoolCatalogueResponse.BranchResponse;
import com.elvencode.schoolba.school.dto.SchoolCatalogueResponse.CourseResponse;
import com.elvencode.schoolba.school.dto.SchoolCatalogueResponse.FaqResponse;
import com.elvencode.schoolba.school.dto.SchoolCatalogueResponse.JourneyStepResponse;
import com.elvencode.schoolba.school.dto.SchoolCatalogueResponse.LearningResourceResponse;
import com.elvencode.schoolba.school.dto.SchoolCatalogueResponse.StatResponse;
import com.elvencode.schoolba.school.dto.SchoolCatalogueResponse.TestimonialResponse;
import com.elvencode.schoolba.school.dto.SchoolCatalogueResponse.TrainingPackageResponse;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class SchoolCatalogueService {

    public SchoolCatalogueResponse getCatalogue() {
        return new SchoolCatalogueResponse(
                List.of("light", "motorcycle", "threewheeler", "heavy"),
                stats(),
                courses(),
                packages(),
                journey(),
                branches(),
                resources(),
                testimonials(),
                faqs()
        );
    }

    private List<StatResponse> stats() {
        return List.of(
                new StatResponse("years", "75"),
                new StatResponse("drivers", "42,000+"),
                new StatResponse("pass", "94%"),
                new StatResponse("branches", "4")
        );
    }

    private List<CourseResponse> courses() {
        return List.of(
                new CourseResponse("car-manual", "light", List.of("B"), 20, 14, 48000, "manual", true),
                new CourseResponse("car-auto", "light", List.of("B"), 16, 12, 42000, "auto", false),
                new CourseResponse("van", "light", List.of("B"), 22, 14, 54000, "manual", false),
                new CourseResponse("motorcycle", "motorcycle", List.of("A"), 12, 8, 26000, "manual", true),
                new CourseResponse("scooter", "motorcycle", List.of("A1"), 8, 6, 18000, "auto", false),
                new CourseResponse("threewheeler", "threewheeler", List.of("B1"), 14, 9, 30000, "manual", false),
                new CourseResponse("lorry", "heavy", List.of("C", "CE"), 26, 18, 96000, "manual", false),
                new CourseResponse("bus", "heavy", List.of("D", "DE"), 28, 20, 108000, "manual", false)
        );
    }

    private List<TrainingPackageResponse> packages() {
        return List.of(
                new TrainingPackageResponse("essential", 34000, 12, false),
                new TrainingPackageResponse("complete", 48000, 20, true),
                new TrainingPackageResponse("fasttrack", 72000, 24, false)
        );
    }

    private List<JourneyStepResponse> journey() {
        return List.of(
                new JourneyStepResponse("medical"),
                new JourneyStepResponse("register"),
                new JourneyStepResponse("written"),
                new JourneyStepResponse("lessons"),
                new JourneyStepResponse("trial"),
                new JourneyStepResponse("licence")
        );
    }

    private List<BranchResponse> branches() {
        return List.of(
                new BranchResponse("rajagiriya", "branch", "077 480 1120", List.of("light", "motorcycle", "threewheeler", "heavy"), "Cotta Road, Rajagiriya, Sri Lanka"),
                new BranchResponse("wellawatte", "branch", "077 480 1121", List.of("light", "motorcycle", "threewheeler"), "Galle Road, Colombo 06, Sri Lanka"),
                new BranchResponse("battaramulla", "branch", "077 480 1122", List.of("light", "motorcycle", "heavy"), "Pannipitiya Road, Battaramulla, Sri Lanka"),
                new BranchResponse("kaduwela-yard", "yard", "077 480 1123", List.of("light", "motorcycle", "threewheeler"), "Avissawella Road, Kaduwela, Sri Lanka")
        );
    }

    private List<LearningResourceResponse> resources() {
        return List.of(
                new LearningResourceResponse("r1", "tutorial"),
                new LearningResourceResponse("r2", "tutorial"),
                new LearningResourceResponse("r3", "tutorial"),
                new LearningResourceResponse("r4", "paper"),
                new LearningResourceResponse("r5", "paper"),
                new LearningResourceResponse("r6", "paper"),
                new LearningResourceResponse("r7", "rule"),
                new LearningResourceResponse("r8", "rule"),
                new LearningResourceResponse("r9", "rule"),
                new LearningResourceResponse("r10", "blog"),
                new LearningResourceResponse("r11", "blog"),
                new LearningResourceResponse("r12", "blog")
        );
    }

    private List<TestimonialResponse> testimonials() {
        return List.of(
                new TestimonialResponse("t1", "Nimali Perera", "NP", "rajagiriya", 5),
                new TestimonialResponse("t2", "Rajeev Fernando", "RF", "kaduwela-yard", 5),
                new TestimonialResponse("t3", "Ayesha Jayawardena", "AJ", "wellawatte", 4.5),
                new TestimonialResponse("t4", "Sanjay Kumar", "SK", "rajagiriya", 5),
                new TestimonialResponse("t5", "Dilini Silva", "DS", "battaramulla", 5)
        );
    }

    private List<FaqResponse> faqs() {
        return List.of(
                new FaqResponse("f1"),
                new FaqResponse("f2"),
                new FaqResponse("f3"),
                new FaqResponse("f4"),
                new FaqResponse("f5"),
                new FaqResponse("f6"),
                new FaqResponse("f7"),
                new FaqResponse("f8"),
                new FaqResponse("f9"),
                new FaqResponse("f10")
        );
    }
}
