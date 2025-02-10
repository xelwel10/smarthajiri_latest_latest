import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarthajiri/core/app_routes.dart';
import 'package:smarthajiri/core/config.dart';
import 'package:smarthajiri/core/loading_indicator.dart';
import 'package:smarthajiri/core/user_shared_pref.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkToken();

  }

  Future<void> _checkToken() async {
    Future.delayed(const Duration(seconds: 3), () async {
      UserSharedPrefs usp = UserSharedPrefs();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('authToken');
      if (mounted) {
        if (token != null && !usp.isTokenExpired(token)) {
          usp.saveToken(token);
          Navigator.popAndPushNamed(context, AppRoute.navRoute);
        } else {
          Navigator.popAndPushNamed(context, AppRoute.loginRoute);
        }
      }
    });
  }

  String imageName = Config.getSplashImage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 71,
                    width: 152,
                    child: Image.asset(imageName),
                  ),
                  const SizedBox(height: 20),
                  const CustomLoadingIndicator(),
                  const SizedBox(height: 20),
                  const Text(
                    'Version: 2.9.3',
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Developed by: Xelwel Innovation Pvt. Ltd.',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
