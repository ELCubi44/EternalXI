package com.eternalxi.eternalxi_api.progress;

/**
 * Progresión infinita: cada nivel cuesta más, sin techo.
 * XP para pasar de {@code level} a {@code level + 1}.
 */
public final class AccountLevelMath {

    private AccountLevelMath() {}

    public static long xpRequiredForNextLevel(int level) {
        if (level < 1) {
            level = 1;
        }
        double l = level;
        return Math.round(100 + 12 * l + Math.pow(l, 1.35) * 6);
    }

    public static int levelFromTotalXp(long totalXp) {
        if (totalXp < 0) {
            totalXp = 0;
        }
        int level = 1;
        long remaining = totalXp;
        while (true) {
            long need = xpRequiredForNextLevel(level);
            if (remaining < need) {
                return level;
            }
            remaining -= need;
            level++;
        }
    }

    public static long xpIntoCurrentLevel(long totalXp) {
        int level = levelFromTotalXp(totalXp);
        long spent = 0;
        for (int i = 1; i < level; i++) {
            spent += xpRequiredForNextLevel(i);
        }
        return totalXp - spent;
    }

    public static long xpForNextLevelFromTotal(long totalXp) {
        return xpRequiredForNextLevel(levelFromTotalXp(totalXp));
    }

    public static String rankTitle(int level) {
        if (level >= 75) {
            return "Inmortal";
        }
        if (level >= 50) {
            return "Mítico";
        }
        if (level >= 35) {
            return "Leyenda";
        }
        if (level >= 20) {
            return "Estratega";
        }
        if (level >= 10) {
            return "Manager";
        }
        if (level >= 5) {
            return "Aficionado";
        }
        return "Novato";
    }
}
