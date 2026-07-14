package com.eternalxi.eternalxi_api.controller;

import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StreamUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/v1/legal")
public class LegalPagesController {

    private static final Map<String, String> PAGES = Map.of(
            "terms-of-service.html", "legal/terms-of-service.html",
            "privacy-policy.html", "legal/privacy-policy.html",
            "community-guidelines.html", "legal/community-guidelines.html",
            "account-deletion.html", "legal/account-deletion.html"
    );

    private static final Set<String> ALLOWED = PAGES.keySet();

    @GetMapping("/{page}")
    public ResponseEntity<String> serve(@PathVariable String page) throws IOException {
        if (!ALLOWED.contains(page)) {
            return ResponseEntity.notFound().build();
        }
        ClassPathResource resource = new ClassPathResource(PAGES.get(page));
        if (!resource.exists()) {
            return ResponseEntity.notFound().build();
        }
        String html = StreamUtils.copyToString(resource.getInputStream(), StandardCharsets.UTF_8);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML_VALUE + ";charset=UTF-8")
                .body(html);
    }
}
