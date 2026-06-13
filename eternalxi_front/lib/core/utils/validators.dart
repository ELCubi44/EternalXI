import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/core/constants/legal_constants.dart';

class Validators {
  static final _nicknameRegex =
      RegExp(r'^[\p{L}\p{N}_\-.]{3,24}$', unicode: true);

  static String? email(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return l10n.validatorRequiredEmail;
    }
    if (v.length > 190) {
      return l10n.validatorEmailMaxLength;
    }
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(v)) {
      return l10n.validatorInvalidEmail;
    }
    return null;
  }

  static String? password(String? value, AppLocalizations l10n) {
    final v = value ?? '';
    if (v.isEmpty) {
      return l10n.validatorRequiredPassword;
    }
    if (v.length < 8) {
      return l10n.validatorPasswordMinLength;
    }
    if (v.length > 128) {
      return l10n.validatorPasswordMaxLength;
    }
    return null;
  }

  static String? nickname(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return l10n.validatorRequiredNickname;
    }
    if (v.contains(' ')) {
      return l10n.validatorNicknameNoSpaces;
    }
    if (v.length < 3) {
      return l10n.validatorNicknameMinLength;
    }
    if (v.length > 24) {
      return l10n.validatorNicknameMaxLength;
    }
    if (!_nicknameRegex.hasMatch(v)) {
      return l10n.validatorNicknameInvalidChars;
    }
    return null;
  }

  static String? confirmPassword(
    String? value,
    String original,
    AppLocalizations l10n,
  ) {
    if ((value ?? '').isEmpty) {
      return l10n.validatorConfirmPasswordRequired;
    }
    if (value != original) {
      return l10n.validatorPasswordsDontMatch;
    }
    return null;
  }

  static String? verificationCode(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return l10n.validatorRequiredCode;
    }
    return null;
  }

  static String? leagueName(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return l10n.validatorRequiredLeagueName;
    }
    if (v.length < 3) {
      return l10n.validatorLeagueNameMinLength;
    }
    if (v.length > 50) {
      return l10n.validatorLeagueNameMaxLength;
    }
    return null;
  }

  static String? birthDate(String? isoDate, AppLocalizations l10n) {
    if (isoDate == null || isoDate.trim().isEmpty) {
      return l10n.validatorRequiredBirthDate;
    }
    final parts = isoDate.trim().split('-');
    if (parts.length != 3) {
      return l10n.validatorRequiredBirthDate;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return l10n.validatorRequiredBirthDate;
    }
    final birth = DateTime(year, month, day);
    final now = DateTime.now();
    if (birth.isAfter(now)) {
      return l10n.validatorRequiredBirthDate;
    }
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    if (age < LegalConstants.minimumAgeYears) {
      return l10n.validatorUnderMinAge;
    }
    return null;
  }

  static String? invitationCode(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return l10n.validatorRequiredInvitationCode;
    }
    if (v.length > 20) {
      return l10n.validatorInvitationCodeMaxLength;
    }
    return null;
  }
}
