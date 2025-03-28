import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smarthajiri/core/app_routes.dart';
import 'package:smarthajiri/core/config.dart';
import 'package:smarthajiri/core/loading_indicator.dart';
import 'package:smarthajiri/core/snackbar.dart';
import 'package:smarthajiri/model/changepw_model.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

final TextEditingController userNameController = TextEditingController();
final TextEditingController newPwController = TextEditingController();
final TextEditingController confirmNewPwController = TextEditingController();
final TextEditingController otpController = TextEditingController();

class _ForgotPasswordState extends State<ForgotPassword> {
  String initUrl = Config.getHomeUrl();
  final ValueNotifier<bool> _isObscure = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isObscure0 = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoadingNoifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> _page = ValueNotifier<int>(0);

  @override
  void dispose() {
    _isObscure.dispose();
    _isObscure0.dispose();
    _isLoadingNoifier.dispose();
    _page.dispose();
    userNameController.dispose();
    newPwController.dispose();
    confirmNewPwController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Future<bool> checkEmail(String mail, BuildContext context) async {
    final url = Uri.parse('$initUrl/api/forgot_password');
    try {
      final response = await http.post(url, body: {'email': mail});
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData["status"] == "success") {
        return true;
      } else {
        if (responseData["message"] is String) {
          showSnackBar(
            message: responseData["message"],
            context: context,
            color: Colors.red,
          );
        } else {
          showSnackBar(
            message: responseData["message"].join(', '),
            context: context,
            color: Colors.red,
          );
        }
      }
    } catch (e) {
      print('Error occurred: $e');
    }
    return false;
  }

  Future<bool> checkOtp(String otp, String email) async {
    final url = Uri.parse('$initUrl/api/verify_reset_otp');

    try {
      final response = await http.post(url, body: {'otp': otp, 'email': email});

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData["status"] == "success") {
        return true;
      }
    } catch (e) {
      print('Error occurred: $e');
    }
    return false;
  }

  Future<bool> changePassword(
    PasswordModel model,
  ) async {
    final url = Uri.parse('$initUrl/api/reset_password');

    try {
      final response = await http.post(url, body: model.toJson());
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData["status"] == "success") {
        showSnackBar(
          message: responseData["message"],
          context: context,
        );
        return true;
      } else {
        if (responseData["message"] is String) {
          showSnackBar(
            message: responseData["message"],
            context: context,
            color: Colors.red,
          );
        } else {
          showSnackBar(
            message: responseData["message"].join(', '),
            context: context,
            color: Colors.red,
          );
        }
      }
      return false;
    } catch (e) {
      print('Error occurred: $e');
      return false;
    }
  }

  Widget forgotPw() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Column(
            children: [
              Image.asset(
                Config.getSplashImage(),
                height: 71,
                width: 152,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
        const SizedBox(height: 140),
        Align(
          alignment: Alignment.centerLeft,
          child: RichText(
            text: const TextSpan(
              children: <TextSpan>[
                TextSpan(
                  text: 'Forgot password? Provide your ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'email',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: '.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: userNameController,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 7),
            suffixIcon: Icon(Icons.email_outlined),
            hintText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: Colors.orange),
            ),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () async {
            String email = userNameController.text.trim();
            if (email.isEmpty) {
              showSnackBar(
                context: context,
                message: "Please enter your email.",
                color: Colors.red,
              );
            } else {
              _isLoadingNoifier.value = true;

              bool? hasEmail = await checkEmail(email, context);
              _isLoadingNoifier.value = false;

              if (hasEmail) {
                _page.value = 1;
              }
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            backgroundColor: const Color(0xFF0286D0),
          ),
          child: const Text(
            "Submit",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget enterOtp() {
    String email = userNameController.text.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Column(
            children: [
              Image.asset(
                Config.getSplashImage(),
                height: 71,
                width: 152,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
        const SizedBox(height: 140),
        Align(
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              children: <TextSpan>[
                const TextSpan(
                  text: 'An email contining OTP has been sent to ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: '.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: otpController,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 7),
            suffixIcon: Icon(Icons.email_outlined),
            hintText: 'Enter OPT sent to your email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: Colors.orange),
            ),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () async {
            String otp = otpController.text.trim();
            String email = userNameController.text.trim();
            if (otp.isEmpty) {
              showSnackBar(
                context: context,
                message: "Please enter your otp.",
                color: Colors.red,
              );
              return;
            }
            _isLoadingNoifier.value = true;
            bool? isOtp = await checkOtp(otp, email);
            _isLoadingNoifier.value = false;
            if (isOtp) {
              _page.value = 2;
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            backgroundColor: const Color(0xFF0286D0),
          ),
          child: const Text(
            "Change",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget newPw() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Column(
            children: [
              Image.asset(
                Config.getSplashImage(),
                height: 71,
                width: 152,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
        const SizedBox(height: 140),
        ValueListenableBuilder(
            valueListenable: _isObscure,
            builder: (context, isObscure, child) {
              return TextFormField(
                controller: newPwController,
                obscureText: isObscure,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 7),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      _isObscure.value = !_isObscure.value;
                    },
                  ),
                  hintText: 'New Password',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
              );
            }),
        const SizedBox(height: 30),
        ValueListenableBuilder(
            valueListenable: _isObscure0,
            builder: (context, isObscure0, child) {
              return TextFormField(
                controller: confirmNewPwController,
                obscureText: isObscure0,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 7),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscure0 ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      _isObscure0.value = !_isObscure0.value;
                    },
                  ),
                  hintText: 'Confirm New Password',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
              );
            }),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () async {
            String email = userNameController.text.trim();
            String pw = newPwController.text.trim();
            String cpw = confirmNewPwController.text.trim();
            if (pw.isEmpty || cpw.isEmpty) {
              showSnackBar(
                context: context,
                message: "Fields cannot be empty.",
                color: Colors.red,
              );
              return;
            }
            if (pw != cpw) {
              showSnackBar(
                context: context,
                message: "Passwords do not match.",
                color: Colors.red,
              );
              return;
            }
            PasswordModel pm = PasswordModel(
                email: email, password: pw, password_confirmation: cpw);
            _isLoadingNoifier.value = true;
            bool? hasChanged = await changePassword(pm);
            _isLoadingNoifier.value = false;
            if (hasChanged) {
              Navigator.popAndPushNamed(context, AppRoute.loginRoute);
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            backgroundColor: const Color(0xFF0286D0),
          ),
          child: const Text(
            "Change",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Stack(
            children: [
              ValueListenableBuilder(
                  valueListenable: _isLoadingNoifier,
                  builder: (context, isLoading, child) {
                    return !isLoading
                        ? SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ValueListenableBuilder<int>(
                                  valueListenable: _page,
                                  builder: (context, page, child) {
                                    return (page == 0)
                                        ? forgotPw()
                                        : (page == 1)
                                            ? enterOtp()
                                            : newPw();
                                  }),
                            ),
                          )
                        : Positioned.fill(
                            child: Container(
                              color: Colors.white.withValues(),
                              child: Center(
                                child: TickerMode(
                                  enabled:
                                      ModalRoute.of(context)?.isCurrent ?? true,
                                  child: CustomLoadingIndicator(),
                                ),
                              ),
                            ),
                          );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
