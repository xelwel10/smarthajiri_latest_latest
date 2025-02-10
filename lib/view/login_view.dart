import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:smarthajiri/core/app_routes.dart';
import 'package:smarthajiri/core/config.dart';
import 'package:smarthajiri/core/loading_indicator.dart';
import 'package:smarthajiri/core/snackbar.dart';
import 'package:smarthajiri/core/user_shared_pref.dart';
import 'package:smarthajiri/model/login_model.dart';

class LoginPageView extends StatefulWidget {
  const LoginPageView({super.key});

  @override
  State<StatefulWidget> createState() => _LoginPageViewState();
}

class _LoginPageViewState extends State<LoginPageView> {
  bool isLoginSelected = true;
  bool isObscure = true;
  bool _isChecked = true;
  bool isLoading = false;

  String initUrl = Config.getHomeUrl();
  String url = Config.getHomeUrl();

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  CookieManager cookieManager = CookieManager.instance();

  String imageName = Config.getLoginImage();
  UserSharedPrefs usp = UserSharedPrefs();

  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  String? token;
  String? username;
  String? password;
  double imageWidth = 0;
  double imageHeight = 0;
  bool? isBio = Config.getBio();
  @override
  void initState() {
    super.initState();
    _getImageDimensions();
    auth.isDeviceSupported().then(
          (bool isSupported) => setState(() => _supportState = isSupported
              ? _SupportState.supported
              : _SupportState.unsupported),
        );
    _checkBiometrics();
  }

  void _getImageDimensions() async {
    final Image image = Image.asset(imageName);
    final ImageStream stream = image.image.resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      double originalWidth = info.image.width.toDouble();
      double originalHeight = info.image.height.toDouble();
      while (originalHeight >= 73 && originalWidth >= 153) {
        originalWidth /= 1.1;
        originalHeight /= 1.1;
      }

      setState(() {
        imageWidth = originalWidth;
        imageHeight = originalHeight;

        if (originalHeight < 66) {
          imageHeight = 66;
        }
        if (originalWidth < 139) {
          imageWidth = 139;
        }
      });
    }));
  }

  Future<void> _checkBiometrics() async {
    token = await usp.getToken();
    username = await usp.getUsername();

    if (!mounted) {
      return;
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Touch the fingerprint sensor',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      token = await usp.getToken();
      username = await usp.getUsername();
      password = await usp.getPassword();
      LoginModel lm = LoginModel(email: username!, password: password!);
      if (authenticated && username != null) {
        login(lm, context, initUrl, username!, password!);
      }
    } on PlatformException catch (e) {
      print(e);

      return;
    }
    if (!mounted) {
      return;
    }
  }

  Future<void> login(
    LoginModel model,
    BuildContext context,
    String initUrl,
    String username,
    String password,
  ) async {
    final url = Uri.parse('$initUrl/api/v1/mobile_login');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(model.toJson());
    String token = "";
    try {
      final response = await http.post(url, headers: headers, body: body);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData["status"] == "success") {
        UserSharedPrefs usp = UserSharedPrefs();
        usp.setUsername(username);
        usp.setPassword(password);

        showSnackBar(
          message: responseData["message"],
          context: context,
        );
        token = responseData["token"];

        usp.saveToken(token);
        FocusScope.of(context).unfocus();
        // setState(() {
        //   isLoading = false;
        // });
        Navigator.popAndPushNamed(context, AppRoute.navRoute);
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
      print('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
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
                      const SizedBox(height: 15),
                      SizedBox(
                        height: imageHeight,
                        width: imageWidth,
                        child: Image.asset(imageName),
                      ),
                      const SizedBox(height: 10),
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
                            Navigator.pushNamed(context, AppRoute.forgotRoute);
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
                          if (username == "" || password == "") {
                            showSnackBar(
                              context: context,
                              message: "Fields cannot be empty.",
                              color: Colors.red,
                            );
                            return;
                          }
                          FocusScope.of(context).unfocus();
                          setState(() {
                            isLoading = true;
                          });
                          final LoginModel loginModel =
                              LoginModel(email: username, password: password);
                          login(
                            loginModel,
                            context,
                            initUrl,
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
                      Center(
                        child: _supportState != _SupportState.unsupported &&
                                username != null &&
                                isBio!
                            ? GestureDetector(
                                onTap: () async {
                                  await _authenticateWithBiometrics();
                                },
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.fingerprint,
                                      size: 50,
                                      color: Colors.blue,
                                    ),
                                    Text(
                                      'Login with biometric',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(),
                    child: const Center(
                      child: CustomLoadingIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}
