import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:smarthajiri/core/app_routes.dart';
import 'package:smarthajiri/core/config.dart';
import 'package:smarthajiri/core/loading_indicator.dart';
import 'package:smarthajiri/core/snackbar.dart';
import 'package:smarthajiri/core/update_manager.dart';
import 'package:smarthajiri/core/user_shared_pref.dart';
import 'package:smarthajiri/view/dashboard_view.dart';

class LoginPageView extends StatefulWidget {
  const LoginPageView({super.key});

  @override
  State<StatefulWidget> createState() => _LoginPageViewState();
}

class _LoginPageViewState extends State<LoginPageView> {
  bool isObscure = true;
  bool _isChecked = true;
  bool isLoading = false;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();

  final LocalAuthentication auth = LocalAuthentication();
  String? token;
  String? username;
  String? password;
  bool? isBio = false;
  bool isLoggedIn = false;

  final GlobalKey<DashBoardViewState> dashboardPageKey =
      GlobalKey<DashBoardViewState>();

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    FocusScope.of(context).unfocus();
    token = await UserSharedPrefs().getToken();
    username = await UserSharedPrefs().getUsername();
    isBio = await UserSharedPrefs().getBio();
    await UserSharedPrefs().setLogged(isLoggedIn);
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Touch the fingerprint sensor',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        password = await UserSharedPrefs().getPassword();
        if (authenticated && username != null) {
          _login(username!, password!);
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Biometric auth error: $e");
    }
  }

  Future<void> _login(String username, String password) async {
    setState(() => isLoading = true);

    final url = Uri.parse('${Config.getHomeUrl()}/api/v1/mobile_login');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'email': username, 'password': password});

    try {
      final response = await http.post(url, headers: headers, body: body);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData["status"] == "success") {
        await UserSharedPrefs().setUsername(username);
        await UserSharedPrefs().setPassword(password);
        await UserSharedPrefs().saveToken(responseData["token"]);

        showSnackBar(
          message: responseData["message"],
          context: context,
        );
        Config.setToken(responseData["token"]);
        FocusScope.of(context).unfocus();
        dashboardPageKey.currentState?.goToHome();
        await Future.delayed(const Duration(milliseconds: 800));

        setState(() {
          isLoading = false;
          isLoggedIn = true;
          UserSharedPrefs().setLogged(isLoggedIn);
        });
      } else {
        setState(() {
          isLoading = false;
        });
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
      debugPrint("Login error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Config.getUpdateAvailable()) {
      showAppUpdateDialog(context);
    }
    double screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        DashBoardView(key: dashboardPageKey),
        if (!isLoggedIn)
          Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            Center(
                              child: Image.asset(
                                "assets/logo/logo.png",
                                height: 73,
                                width: 153,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 70),
                            TextFormField(
                              controller: userNameController,
                              decoration: const InputDecoration(
                                suffixIcon: Icon(Icons.email_outlined),
                                hintText: 'Username / Email',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8.0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8.0)),
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: passwordController,
                              obscureText: isObscure,
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isObscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isObscure = !isObscure;
                                    });
                                  },
                                ),
                                hintText: 'Password',
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8.0)),
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8.0)),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, AppRoute.forgotRoute);
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                final username = userNameController.text.trim();
                                final password = passwordController.text.trim();
                                if (username.isEmpty || password.isEmpty) {
                                  showSnackBar(
                                    context: context,
                                    message: "Fields cannot be empty.",
                                    color: Colors.red,
                                  );
                                  return;
                                }
                                FocusScope.of(context).unfocus();
                                isLoading = true;
                                _login(
                                  username,
                                  password,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                backgroundColor: const Color(0xFF0286D0),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontFamily: 'inherit',
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 35),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoute.attendenceRoute,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                backgroundColor: const Color(0xFF0286D0),
                              ),
                              child: const Text(
                                "Submit Attendance",
                                style: TextStyle(
                                  fontFamily: 'inherit',
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        activeColor: Colors.orange,
                                        value: _isChecked,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _isChecked = value ?? false;
                                          });
                                        },
                                      ),
                                      Text(
                                        "By signing in you are agreeing to our",
                                        style: TextStyle(
                                          fontFamily: 'inherit',
                                          fontSize: screenWidth * 0.041,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Transform.translate(
                                    offset: const Offset(0, -9),
                                    child: InkWell(
                                      child: Text(
                                        'Term and privacy policy',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontFamily: 'inherit',
                                          fontSize: screenWidth * 0.041,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pushNamed(
                                            context, AppRoute.policyRoute);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 35),
                            if (isBio == true && username != null)
                              GestureDetector(
                                onTap: _authenticateWithBiometrics,
                                child: Column(
                                  children: const [
                                    Icon(Icons.fingerprint,
                                        size: 50, color: Colors.blue),
                                    Text(
                                      'Login with biometric',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (isLoading)
          Container(
            color: Colors.white.withValues(),
            child: Center(
              child: TickerMode(
                enabled: ModalRoute.of(context)?.isCurrent ?? true,
                child: CustomLoadingIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}
