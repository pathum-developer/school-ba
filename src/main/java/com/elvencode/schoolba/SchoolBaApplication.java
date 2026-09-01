package com.elvencode.schoolba;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@EnableCaching
@SpringBootApplication
@EnableJpaAuditing(auditorAwareRef = "auditorAwareImpl")
public class SchoolBaApplication {

    public static void main(String[] args) {
        SpringApplication.run(SchoolBaApplication.class, args);
    }

}
