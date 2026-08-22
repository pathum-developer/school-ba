package com.elvencode.schoolba;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties =
        "app.auth.jwt.signing-key-base64=MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=")
class SchoolBaApplicationTests {

    @Test
    void contextLoads() {
    }

}
