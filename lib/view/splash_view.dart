import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarthajiri/core/app_routes.dart';
import 'package:smarthajiri/core/config.dart';
import 'package:smarthajiri/core/loading_indicator.dart';
import 'package:smarthajiri/core/update_manager.dart';
import 'package:smarthajiri/core/user_shared_pref.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

String _appVersion = '';

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkToken();
    checkAppUpdates();
    _appVersion = Config.getAppVersion();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
      precacheImage(AssetImage(Config.getSplashImage()), context);
    });
  }

  Future<String?> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> _checkToken() async {
    String? token = await _loadToken();
    if (!mounted) return;

    if (token != null && !UserSharedPrefs().isTokenExpired(token)) {
      UserSharedPrefs().saveToken(token);
      Config.setStopLoading(true);
      Navigator.popAndPushNamed(context, AppRoute.navRoute);
    } else {
      Navigator.popAndPushNamed(context, AppRoute.loginRoute);
    }
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
                    child: Image.asset(Config.getSplashImage()),
                  ),
                  const SizedBox(height: 20),
                  TickerMode(
                    enabled: ModalRoute.of(context)?.isCurrent ?? true,
                    child: CustomLoadingIndicator(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Version: $_appVersion',
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
