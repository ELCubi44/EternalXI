class Validators {
  static final _nicknameRegex =
      RegExp(r'^[\p{L}\p{N}_\-.]{3,24}$', unicode: true);

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'El correo es obligatorio';
    }
    if (v.length > 190) {
      return 'Máximo 190 caracteres';
    }
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(v)) {
      return 'Correo inválido';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (v.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (v.length > 128) {
      return 'Máximo 128 caracteres';
    }
    return null;
  }

  static String? nickname(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'El nickname es obligatorio';
    }
    if (v.contains(' ')) {
      return 'El nickname no puede contener espacios';
    }
    if (v.length < 3) {
      return 'Mínimo 3 caracteres';
    }
    if (v.length > 24) {
      return 'Máximo 24 caracteres';
    }
    if (!_nicknameRegex.hasMatch(v)) {
      return 'Solo letras, números, guiones, puntos y guiones bajos';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) {
      return 'Confirma la contraseña';
    }
    if (value != original) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  static String? verificationCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'El código es obligatorio';
    }
    return null;
  }

  static String? leagueName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'El nombre de la liga es obligatorio';
    }
    if (v.length < 3) {
      return 'Mínimo 3 caracteres';
    }
    if (v.length > 50) {
      return 'Máximo 50 caracteres';
    }
    return null;
  }

  static String? invitationCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Introduce el código de invitación';
    }
    if (v.length > 20) {
      return 'Máximo 20 caracteres';
    }
    return null;
  }
}
