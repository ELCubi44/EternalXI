package com.eternalxi.eternalxi_api.util;

public record CatalogLocale(String code) {

    public static CatalogLocale from(String queryLang, String acceptLanguage) {
        return new CatalogLocale(LocaleSupport.resolveCatalogLocale(queryLang, acceptLanguage));
    }
}
