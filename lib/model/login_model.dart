class LoginModel {
  final String email;
  final String password;

  const LoginModel({
    required this.email,
    required this.password,
  });
  toJson() {
    return {
      "email": email,
      "password": password,
    };
  }

  factory LoginModel.fromJson(Map<String, dynamic> data) {
    return LoginModel(
      email: data["email"],
      password: data["password"],
    );
  }
}
