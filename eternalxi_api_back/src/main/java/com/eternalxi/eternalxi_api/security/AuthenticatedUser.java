package com.eternalxi.eternalxi_api.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public final class AuthenticatedUser {

    private AuthenticatedUser() {
    }

    public static Long currentUserIdOrNull() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return null;
        }
        Object principal = auth.getPrincipal();
        if (principal instanceof UserPrincipal userPrincipal) {
            return userPrincipal.userId();
        }
        return null;
    }

    public static long requireUserId() {
        Long id = currentUserIdOrNull();
        if (id == null) {
            throw new org.springframework.security.access.AccessDeniedException("No autenticado");
        }
        return id;
    }

    public static void assertSameUser(long requestedUserId) {
        long current = requireUserId();
        if (current != requestedUserId) {
            throw new org.springframework.security.access.AccessDeniedException("No puedes actuar como otro usuario");
        }
    }
}
