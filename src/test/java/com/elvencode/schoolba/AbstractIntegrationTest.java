package com.elvencode.schoolba;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

/**
 * Base class for tests that need a real database.
 *
 * <p>Tests run against the dedicated school_db_test instance declared in docker-compose.yml, never
 * against the development database. Two mechanisms keep it clean:
 *
 * <ul>
 *   <li>{@code @Transactional} wraps each test method and rolls back afterwards, so rows a test
 *       writes are never committed.
 *   <li>{@code spring.liquibase.drop-first} rebuilds the schema from the changelogs at the start
 *       of every run, discarding anything that escaped rollback.
 * </ul>
 *
 * <p>Rollback only covers work done on the test thread, which includes MockMvc. A test that starts
 * a real HTTP server ({@code webEnvironment = RANDOM_PORT}) handles the request on another thread
 * in its own transaction, so such a test must clean up after itself.
 *
 * <p>Every annotation lives here rather than on individual tests so all tests share one Spring
 * context. Adding {@code @AutoConfigureMockMvc} to only some of them would give those a different
 * context cache key, and the context would be built more than once per run.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public abstract class AbstractIntegrationTest {

    /**
     * Contributed by MockMvcAutoConfiguration, which {@code @AutoConfigureMockMvc} activates
     * through Spring Boot's test-slice mechanism. IDE inspections do not evaluate test slices and
     * report this as a missing bean; the bean is present at runtime, hence the suppression.
     */
    @SuppressWarnings("SpringJavaInjectionPointsAutowiringInspection")
    @Autowired
    protected MockMvc mockMvc;
}
