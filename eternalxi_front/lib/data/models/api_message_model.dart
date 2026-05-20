class ApiMessageModel {
  const ApiMessageModel({required this.message});

  final String message;

  factory ApiMessageModel.fromJson(Map<String, dynamic> json) {
    return ApiMessageModel(message: (json['message'] ?? '').toString());
  }
}
