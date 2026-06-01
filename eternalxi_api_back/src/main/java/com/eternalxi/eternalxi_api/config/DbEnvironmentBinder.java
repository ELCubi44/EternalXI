package com.eternalxi.eternalxi_api.config;

import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

@Component
public class DbEnvironmentBinder implements ApplicationListener<ContextRefreshedEvent> {

    @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        Environment env = event.getApplicationContext().getEnvironment();
        DBConnection.bindEnvironment(env);
    }
}
