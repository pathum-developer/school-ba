package com.elvencode.schoolba.ztemplate.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/logging")
public class LoggingController {

    private static final Logger LOGGER = LoggerFactory.getLogger(LoggingController.class);

    @GetMapping(version = "1.0+")
    public ResponseEntity<String> testLogging() {
        LOGGER.trace("TRACE: This is a very detailed trace log. Used for tracking execution flow.");
        LOGGER.debug("DEBUG: This is a debug message. Used for debugging.");
        LOGGER.info("INFO: This is an informational message. Application events.");
        LOGGER.warn("WARN: This is a warning. Something might go wrong.");
        LOGGER.error("ERROR: An error occurred. This needs immediate attention.");

        return ResponseEntity.ok("Logging tested successfully");
    }
}
