class OAuthProvidersResponse {
  const OAuthProvidersResponse({
    required this.google,
    required this.apple,
  });

  final bool google;
  final bool apple;

  factory OAuthProvidersResponse.fromJson(Map<String, dynamic> json) {
    return OAuthProvidersResponse(
      google: json['google'] == true,
      apple: json['apple'] == true,
    );
  }
}
