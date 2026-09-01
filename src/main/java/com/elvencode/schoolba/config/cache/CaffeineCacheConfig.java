package com.elvencode.schoolba.config.cache;

import java.util.List;
import java.util.concurrent.TimeUnit;

import com.elvencode.schoolba.common.constants.CacheConstant;
import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.caffeine.CaffeineCache;
import org.springframework.cache.support.SimpleCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CaffeineCacheConfig {

    @Bean
    public CacheManager caffeineCacheManager() {
        CaffeineCache activeBranchesBySchoolIdCache = new CaffeineCache(
                CacheConstant.ACTIVE_BRANCHES_BY_SCHOOL_ID,
                Caffeine.newBuilder()
                        .expireAfterWrite(10, TimeUnit.MINUTES)
                        .maximumSize(500)
                        .build()
        );

        SimpleCacheManager manager = new SimpleCacheManager();
        manager.setCaches(List.of(activeBranchesBySchoolIdCache));
        return manager;
    }
}
