class PasswordModel {
  final String email;
  final String password;
  final String password_confirmation;

  const PasswordModel({
    required this.email,
    required this.password,
    required this.password_confirmation,
  });
  toJson() {
    return {
      "email": email,
      "password": password,
      'password_confirmation': password_confirmation,
    };
  }

  factory PasswordModel.fromJson(Map<String, dynamic> data) {
    return PasswordModel(
        email: data["email"],
        password: data["password"],
        password_confirmation: data["password_confirmation"]);
  }
}
