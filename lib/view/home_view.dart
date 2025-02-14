import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarthajiri/core/app_routes.dart';
import 'package:smarthajiri/core/config.dart';
import 'package:smarthajiri/core/loading_indicator.dart';
import 'package:smarthajiri/core/user_shared_pref.dart';
import 'package:smarthajiri/model/device_model.dart';
import 'package:url_launcher/url_launcher.dart';

String firstUrl = "   ";

class HomePageView extends StatefulWidget {
  final String? tempUrl;
  final String? token;
  final int? selectedIndex;
  final String? goingTO;

  const HomePageView({
    super.key,
    this.tempUrl,
    this.selectedIndex,
    this.token,
    this.goingTO,
  });

  @override
  State<HomePageView> createState() => HomePageViewState();
}

class HomePageViewState extends State<HomePageView> {
  UserSharedPrefs usp = UserSharedPrefs();
  InAppWebViewController? webViewController;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isConnected = Config.getInternet();
  final GlobalKey webViewKey = GlobalKey();
  String tempUrl = Config.getHomeUrl();

  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    builtInZoomControls: false,
    displayZoomControls: false,
    useWideViewPort: true,
    iframeAllowFullscreen: true,
    supportZoom: false,
    javaScriptEnabled: true,
    cacheMode: CacheMode.LOAD_NO_CACHE,
    useHybridComposition: true,
    allowUniversalAccessFromFileURLs: true,
    clearSessionCache: false,
    supportMultipleWindows: true,
    allowFileAccessFromFileURLs: true,
  );
  PullToRefreshController? pullToRefreshController;

  String initUrl = Config.getHomeUrl();
  String url = Config.getHomeUrl();
  String? token;
  bool isLoading = false;
  DeviceModel? info;
  double progress = 0;
  final urlController = TextEditingController();
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    checkConnectivity();

    // _loadLastUrl();
    // token = widget.token;
    tempUrl = (widget.tempUrl != null && widget.tempUrl!.isNotEmpty)
        ? widget.tempUrl!
        : Config.getHomeUrl();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.blue),
      onRefresh: _handleRefresh,
    );

    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.white,
    //   statusBarIconBrightness: Brightness.dark,
    //   statusBarBrightness: Brightness.light,
    // ));
    // NotificationHandler.initialize();
  }

  Future<void> checkConnectivity() async {
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isConnected = result.first != ConnectivityResult.none;
        Config.hasInternet(_isConnected);
      });
    });
    if (_isConnected) {
      _applySettingsAndReload();
    }
  }

  Future<void> _getDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        info = DeviceModel(
          brand: androidInfo.brand,
          model: androidInfo.model,
          id: androidInfo.id,
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        info = DeviceModel(
          brand: iosInfo.systemName,
          model: iosInfo.model,
          id: iosInfo.systemVersion,
        );
      }
    } catch (e) {
      print('Error getting device info: $e');
    }
  }

  Future<void> _applySettingsAndReload() async {
    if (webViewController != null) {
      // await webViewController?.setSettings(settings: settings);
      if (url == initUrl ||
          url == "$initUrl/login" ||
          url == "$initUrl/cpaneladmin" ||
          url == "$initUrl/forgot_password") {
        if (mounted) {
          setState(() {
            url = "$initUrl/dashboard";
          });
        }
      }

      try {
        bool hasTempUrl = tempUrl != "";
        webViewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri(hasTempUrl ? tempUrl : url)),
        );
      } catch (e) {
        print("Error in loading url: $e");
      }
    }
  }

  Future<void> _saveLastUrl(String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastUrl', url);
  }

  // Future<void> _loadLastUrl() async {
  //   token = await usp.getToken();

  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? lastUrl = prefs.getString('lastUrl');
  //   if (lastUrl != null) {
  //     if (mounted) {
  //       setState(() {
  //         url = lastUrl;
  //       });
  //     }
  //   }
  // }

  Future<void> _checkLoginTextAndNavigate() async {
    if (webViewController != null) {
      bool? result = await webViewController?.evaluateJavascript(
        source: '''
      (function() {
        return document.querySelector('.login .app.align-items-center .container .login_wrapper') !== null;      
        })();
      ''',
      );

      if (result == true) {
        if (mounted) {
          setState(() {
            isLoading = true;
          });
          usp.deleteToken();
          Navigator.popAndPushNamed(context, AppRoute.loginRoute);
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    await checkConnectivity();
    await InAppWebViewController.clearAllCache();
    await webViewController?.reload();
    pullToRefreshController?.endRefreshing();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headers = {'Authorization': 'Bearer $token'};
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: Colors.orange,
              key: _refreshIndicatorKey,
              onRefresh: _handleRefresh,
              child: _isConnected
                  ? InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(
                        url: WebUri((tempUrl != "") ? tempUrl : url),
                        headers: headers,
                      ),
                      initialSettings: settings,
                      pullToRefreshController: pullToRefreshController,
                      onWebViewCreated: (controller) async {
                        webViewController = controller;
                        webViewController?.setSettings(settings: settings);
                      },
                      onLoadStart: (controller, url) async {
                        _checkLoginTextAndNavigate();

                        token = await usp.getToken();

                        String injectToken = '''
                            (function() {
                                return localStorage.setItem('backend-jwt-token', '$token');
                            })();
                        ''';
                        await webViewController?.evaluateJavascript(
                            source: injectToken);
                        if (mounted) {
                          setState(() {
                            this.url = url.toString();
                            isLoading = true;
                          });
                        }
                      },
                      onPermissionRequest: (controller, request) async {
                        return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT,
                        );
                      },
                      onLoadStop: (controller, initUrl) async {
                        Config.setFirstLoad(false);
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                        await _checkLoginTextAndNavigate();

                        token = await usp.getToken();

                        String injectToken = '''
                            (function() {
                                return localStorage.setItem('backend-jwt-token', '$token');
                            })();
                        ''';
                        await webViewController?.evaluateJavascript(
                            source: injectToken);

                        pullToRefreshController?.endRefreshing();
                        if (mounted) {
                          setState(() {
                            url = initUrl.toString();
                            urlController.text = this.initUrl;
                          });
                        }
                        _saveLastUrl(this.initUrl);

                        await webViewController?.evaluateJavascript(source: '''
                          var meta = document.createElement('meta');
                          meta.name = 'viewport';
                          meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                          document.getElementsByTagName('head')[0].appendChild(meta);
                        ''');

                        await webViewController?.setSettings(
                          settings: InAppWebViewSettings(
                            cacheMode: CacheMode.LOAD_DEFAULT,
                          ),
                        );
                      },
                      onUpdateVisitedHistory:
                          (controller, initUrl, androidIsReload) async {
                        if (mounted) {
                          setState(() {
                            url = initUrl.toString();
                            urlController.text = this.initUrl;
                          });
                        }

                        _saveLastUrl(url);
                        await _checkLoginTextAndNavigate();
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        // print("CONSOLE OUTPUT=-------------");
                        // print(consoleMessage.message);
                        // if (consoleMessage.message
                        //     .contains("ERR_BLOCKED_BY_CLIENT")) {
                        //   showNotification(consoleMessage.message);
                        // }
                        if (kDebugMode) {
                          print(consoleMessage);
                        }
                      },
                      onLoadResource: (controller, resource) {
                        if (resource.url.toString().contains("login")) {
                          usp.deleteToken();
                          if (mounted) {
                            Navigator.pushNamed(context, AppRoute.loginRoute);
                          }
                        }
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        var uri = navigationAction.request.url!;
                        if (![
                          "http",
                          "https",
                          "file",
                          "chrome",
                          "data",
                          "javascript",
                          "about"
                        ].contains(uri.scheme)) {
                          if (await canLaunchUrl(WebUri(uri.toString()))) {
                            await launchUrl(WebUri(uri.toString()));
                            return NavigationActionPolicy.CANCEL;
                          }
                        }
                        return NavigationActionPolicy.ALLOW;
                      },
                    )
                  : const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off,
                              color: Colors.redAccent,
                              size: 100,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'No Internet Connection',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Please check your internet settings and try again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
            ),
            if (isLoading)
              Container(
                color:  Colors.white.withValues(),
                child: const Center(
                  child: CustomLoadingIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> injectProfileButtonScript() async {
    setState(() {
      isLoading = true;
    });
    if (webViewController != null) {
      await webViewController?.evaluateJavascript(source: '''
        (function() {
          var profileButton = document.querySelector('.nav-link[href="/profile"]');
          if (profileButton) {
            profileButton.click();
          }
        })();
      ''');
    }
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      isLoading = false;
    });
  }

  Future<void> injectHomeButtonScript() async {
    setState(() {
      isLoading = true;
    });
    if (webViewController != null) {
      await webViewController?.evaluateJavascript(source: '''
        (function() {
          var homeButton = document.querySelector('.nav-link[href="/dashboard"]');
          if (homeButton) {
            homeButton.click();
          }
        })();
      ''');
    }
    await Future.delayed(const Duration(milliseconds: 750));
    setState(() {
      isLoading = false;
    });
  }
}

class NotificationHandler {
  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // Handle background messages here
    print("IN NOTIFICAITON HANDLER ----------------");
    print('Background message received: ${message.messageId}');
  }

  static void onMessageOpenedApp(Function(RemoteMessage message) listener) {
    FirebaseMessaging.onMessageOpenedApp.listen(listener);
  }

  static void onMessage(Function(RemoteMessage message) listener) {
    FirebaseMessaging.onMessage.listen(listener);
  }
}
