import 'package:eternal_xi/data/models/user_model.dart';

class RegisterResponseModel {
  const RegisterResponseModel({required this.message, required this.user});

  final String message;
  final UserModel user;

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      message: (json['message'] ?? '').toString(),
      user: UserModel.fromJson((json['user'] as Map<String, dynamic>? ?? {})),
    );
  }
}
