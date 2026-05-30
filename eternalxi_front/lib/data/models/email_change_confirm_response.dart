import 'package:eternal_xi/data/models/user_model.dart';

class EmailChangeConfirmResponse {
  const EmailChangeConfirmResponse({
    required this.message,
    required this.user,
  });

  final String message;
  final UserModel user;

  factory EmailChangeConfirmResponse.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    return EmailChangeConfirmResponse(
      message: (json['message'] ?? '').toString(),
      user: UserModel.fromJson(
        userRaw is Map<String, dynamic>
            ? userRaw
            : Map<String, dynamic>.from(userRaw as Map),
      ),
    );
  }
}
