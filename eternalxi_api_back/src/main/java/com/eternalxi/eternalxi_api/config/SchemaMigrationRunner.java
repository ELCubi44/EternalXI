package com.eternalxi.eternalxi_api.config;

import com.eternalxi.eternalxi_api.services.SchemaMigrationService;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class SchemaMigrationRunner implements ApplicationRunner {

    private final SchemaMigrationService schemaMigrationService;

    public SchemaMigrationRunner(SchemaMigrationService schemaMigrationService) {
        this.schemaMigrationService = schemaMigrationService;
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        schemaMigrationService.applyPendingMigrations();
    }
}
