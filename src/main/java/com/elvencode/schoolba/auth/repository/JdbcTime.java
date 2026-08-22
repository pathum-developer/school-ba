package com.elvencode.schoolba.auth.repository;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;

final class JdbcTime {

    private JdbcTime() {
    }

    static OffsetDateTime utc(Instant instant) {
        return instant.atOffset(ZoneOffset.UTC);
    }
}
