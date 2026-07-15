package com.eternalxi.eternalxi_api.util;

public final class UserPublicTag {

    private static final int MULTIPLIER = 7919;
    private static final int OFFSET = 104729;
    private static final int MOD = 900000;
    private static final int BASE = 100000;

    private UserPublicTag() {}

    public static int codeForUserId(long userId) {
        if (userId <= 0) {
            return BASE;
        }
        return BASE + (int) ((userId * MULTIPLIER + OFFSET) % MOD);
    }

    public static Long userIdFromTagCode(int tagCode) {
        if (tagCode < BASE || tagCode >= BASE + MOD) {
            return null;
        }
        int target = tagCode - BASE;
        for (long id = 1; id <= 5_000_000L; id++) {
            if (((id * MULTIPLIER + OFFSET) % MOD) == target) {
                return id;
            }
        }
        return null;
    }
}
