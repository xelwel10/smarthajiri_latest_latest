import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:smarthajiri/core/app_routes.dart';
import 'package:smarthajiri/core/config.dart';
import 'package:smarthajiri/core/loading_indicator.dart';
import 'package:smarthajiri/core/user_shared_pref.dart';
import 'package:smarthajiri/model/device_model.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({
    super.key,
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

  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: false,
    iframeAllow: "camera; microphone",
    builtInZoomControls: false,
    displayZoomControls: false,
    useWideViewPort: true,
    iframeAllowFullscreen: false,
    supportZoom: false,
    javaScriptEnabled: true,
    cacheMode: CacheMode.LOAD_NO_CACHE,
    useHybridComposition: true,
    allowUniversalAccessFromFileURLs: true,
    clearSessionCache: true,
    supportMultipleWindows: false,
    allowFileAccessFromFileURLs: true,
  );
  PullToRefreshController? pullToRefreshController;

  String initUrl = Config.getHomeUrl();
  String url = Config.getHomeUrl();
  String tempUrl = Config.getHomeUrl();
  String token = Config.getToken();
  DeviceModel? info;
  double progress = 0;
  final urlController = TextEditingController();
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();

    checkConnectivity();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.blue),
      onRefresh: _handleRefresh,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    });
  }

  Future<void> checkConnectivity() async {
    token = await usp.getToken();
    Connectivity().onConnectivityChanged.listen((result) {
      bool isConnected = result != ConnectivityResult.none;
      Config.hasInternet(isConnected);
      if (isConnected) {
        _applySettingsAndReload();
      } else {
        setState(() {
          _isConnected = false;
        });
      }
    });
  }

  Future<void> _applySettingsAndReload() async {
    if (webViewController != null) {
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

  Future<void> _checkLoginTextAndNavigate() async {
    if (webViewController != null && !Config.getFirstLoad()) {
      bool? result = await webViewController?.evaluateJavascript(
        source: '''
      (function() {
        var signInText = document.querySelector('small.mt-1') && document.querySelector('small.mt-1').innerText.trim() === 'Sign in to your account.';
        return signInText;
        })();
      ''',
      );
      if (result == true) {
        if (mounted) {
          Config.setFirstLoad(true);
          usp.deleteToken();
          Navigator.popAndPushNamed(context, AppRoute.loginRoute);
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (_isConnected && !_isLoadingNotifier.value) {
      await InAppWebViewController.clearAllCache();
      await webViewController?.reload();
    }
    if (mounted) {
      pullToRefreshController?.endRefreshing();
    }
  }

  @override
  void dispose() {
    super.dispose();
    webViewController?.dispose();
    Connectivity().onConnectivityChanged.drain();
    pullToRefreshController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headers = {'Authorization': 'Bearer $token'};

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: _isLoadingNotifier,
          builder: (_, loading, __) {
            return Stack(
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
                            _isLoadingNotifier.value = true;
                          },
                          onPermissionRequest: (controller, request) async {
                            return PermissionResponse(
                              resources: request.resources,
                              action: PermissionResponseAction.GRANT,
                            );
                          },
                          onUpdateVisitedHistory:
                              (controller, initUrl, androidIsReload) async {
                            await _checkLoginTextAndNavigate();
                          },
                          onLoadStop: (controller, initUrl) async {
                            if (Config.getStopLoading()) {
                              _isLoadingNotifier.value = false;
                            }

                            pullToRefreshController?.endRefreshing();
                            if (mounted) {
                              setState(() {
                                url = initUrl.toString();
                                urlController.text = this.initUrl;
                              });
                            }
                            await webViewController
                                ?.evaluateJavascript(source: '''
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
                            Config.setFirstLoad(false);
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
                if (loading)
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
          },
        ),
      ),
    );
  }

  Future<void> injectProfileButtonScript() async {
    _isLoadingNotifier.value = true;

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
    await Future.delayed(const Duration(milliseconds: 200));
    _isLoadingNotifier.value = false;
  }

  Future<void> injectHomeButtonScript() async {
    _isLoadingNotifier.value = true;

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
    await Future.delayed(const Duration(milliseconds: 800));
    _isLoadingNotifier.value = false;
  }

  void injectTokenAndReload() async {
    if (webViewController != null) {
      token = await usp.getToken();
      String injectToken = '''
        (function() {
            return localStorage.setItem('backend-jwt-token', '$token');
        })();
        ''';

      if (mounted) {
        await webViewController?.evaluateJavascript(source: injectToken);
        await webViewController?.reload();
      }
      Config.setStopLoading(true);
    }
  }
}
