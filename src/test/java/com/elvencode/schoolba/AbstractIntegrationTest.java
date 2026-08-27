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
 *   <li>The test changelog truncates every table at the start of the run, discarding anything that
 *       escaped rollback.
 * </ul>
 *
 * <p>Rollback only covers work done on the test thread, which includes MockMvc. A test that starts
 * a real HTTP server ({@code webEnvironment = RANDOM_PORT}) handles the request on another thread
 * in its own transaction, so such a test must clean up after itself.
 *
 * <h2>Keep every annotation on this class</h2>
 *
 * <p>Spring caches a test context per distinct configuration. Because every test class inherits
 * exactly the annotations below and adds none of its own, the whole suite shares one context:
 * building it costs around thirteen seconds, and each further test class then costs milliseconds.
 *
 * <p>Adding any of these to a subclass gives that class a different cache key and pays for a second
 * context:
 *
 * <ul>
 *   <li>{@code @ActiveProfiles}, {@code @TestPropertySource}, or
 *       {@code @SpringBootTest(properties = ...)}
 *   <li>{@code @MockitoBean} or {@code @MockitoSpyBean}, once per distinct set of replaced beans
 *   <li>{@code @AutoConfigureMockMvc}, or any other slice annotation, applied to only some classes
 * </ul>
 *
 * <p>{@code @DirtiesContext} is worse than a second context: it discards the cached one, so every
 * class that runs after it pays full startup again. Do not use it here.
 *
 * <p>When a test genuinely needs a different configuration, give it its own base class rather than
 * annotating one test, so the cost is paid once and is visible.
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
