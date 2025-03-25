import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:refresh/refresh.dart';
import 'package:smarthajiri/core/app_routes.dart';
import 'package:smarthajiri/core/config.dart';
import 'package:smarthajiri/core/loading_indicator.dart';
import 'package:smarthajiri/core/snackbar.dart';
import 'package:smarthajiri/core/user_shared_pref.dart';
import 'package:smarthajiri/model/attendence_model.dart';
import 'package:smarthajiri/model/checkin_model.dart';
import 'package:smarthajiri/model/device_model.dart';

class WebAttendanceView extends StatefulWidget {
  final DeviceModel? info;
  final int? selectedIndex;

  const WebAttendanceView({
    super.key,
    this.info,
    this.selectedIndex,
  });

  @override
  State<WebAttendanceView> createState() => WebAttendanceViewState();
}

class WebAttendanceViewState extends State<WebAttendanceView>
    with WidgetsBindingObserver {
  UserSharedPrefs usp = UserSharedPrefs();
  final LocalAuthentication auth = LocalAuthentication();

  final ValueNotifier<String> _attType = ValueNotifier<String>("CHECKIN");
  TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  double? lat;
  double? lon;
  String? token;
  Location location = Location();
  bool _isLocationEnabled = true;
  InAppWebViewController? webViewController;
  Timer? _locationServiceTimer;
  bool _isDialogOpen = false;
  final ValueNotifier<bool> _isLocationDialogOpen = ValueNotifier<bool>(false);
  bool isRequestingLocation = false;
  bool serviceEnabled = false;
  Timer? _timer;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _allClients = ['client1', 'client2'];
  final List<double> allLon = [];
  final List<String> _clientIds = ['1'];
  final List<double> allLat = [];
  final List<double> allCoverage = [];
  final ValueNotifier<List<String>> _filteredClients =
      ValueNotifier<List<String>>([]);
  bool _isConnected = true;
  String? username;
  bool? isBio = false;
  String? password;
  double screenWidth = 100;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isNotEmpty = false;
  Timer? _inactivityTimer;
  String address = 'Searching...';
  StreamSubscription<Position>? _locationStreamSubscription;
  final ValueNotifier<bool> _isChecked = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isObscure = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _showMap = ValueNotifier<bool>(false);

  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  String initUrl = Config.getHomeUrl();
  DeviceModel? deviceInfo;

  @override
  void initState() {
    super.initState();
    initialize();
    deviceInfo = widget.info;

    _filteredClients.value = _allClients;
    _searchController.addListener(_filterClients);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnectivity();
      _fetchClients();
    });
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(() {
      if (_isNotEmpty != _searchController.text.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isNotEmpty = _searchController.text.isNotEmpty;
          });
        }
      }
    });
  }

  void initialize() async {
    token = await usp.getToken();
    username = await usp.getUsername();
    isBio = await usp.getBio();
    _fetchClients();
  }

  void _onRefresh() async {
    initialize();
    bool isLogged = await usp.getLogged() ?? false;
    if (token == null || token == '' && isLogged) {
      showSnackBar(context: context, message: "Logged out due to inactivity.");
      Navigator.popAndPushNamed(context, AppRoute.loginRoute);
    }
    userNameController = TextEditingController(text: username);
    await _checkConnectivity();
    await _checkAndRequestLocationServices();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (context.mounted) {
        await _fetchClients();
      }
    });
    _refreshController.refreshCompleted();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _startInactivityTimer();
      _connectivitySubscription.cancel();
      _timer?.cancel();
      _locationServiceTimer?.cancel();
      webViewController?.pauseTimers();
    } else if (state == AppLifecycleState.resumed) {
      webViewController?.resumeTimers();
      _cancelInactivityTimer();
      _onRefresh();
    } else if (state == AppLifecycleState.detached) {
      dispose();
    }
  }

  void _startInactivityTimer() {
    _cancelInactivityTimer();
    _inactivityTimer = Timer(const Duration(minutes: 10), () async {
      await usp.deleteToken();
      debugPrint('Token deleted due to inactivity');
    });
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
  }

  String url = "";

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
      password = await usp.getPassword();
      if (authenticated && username != null) {
        _login(username!, password!);
      }
    } on PlatformException catch (e) {
      print(e);

      return;
    }
    if (!mounted) {
      return;
    }
  }

  Future<int> _checkAndRequestLocationServices() async {
    if (widget.selectedIndex != null) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
          widget.selectedIndex != 1 ||
          isRequestingLocation) {
        return 0;
      }
    }

    isRequestingLocation = true;
    _retryGetLocation();
    if (lat != null && lon != null && address != 'Searching...') {
      isRequestingLocation = false;

      return 1;
    }

    final status = await Permission.location.request();
    if (status.isDenied) {
      showSnackBar(
        context: context,
        message: "Location permission is required.",
        color: Colors.red,
      );
      isRequestingLocation = false;

      return 0;
    } else if (status.isPermanentlyDenied) {
      openAppSettingsDialog();

      _timer = Timer.periodic(const Duration(seconds: 15), (timer) async {
        if (status.isPermanentlyDenied) {
          openAppSettingsDialog();

          return;
        }
      });
      isRequestingLocation = false;

      return 0;
    } else {
      _timer?.cancel();

      _locationServiceTimer =
          Timer.periodic(const Duration(seconds: 15), (timer) async {
        serviceEnabled = await location.serviceEnabled();
        if (!serviceEnabled && !_isLocationDialogOpen.value) {
          _showLocationServiceDialog();
          if (!serviceEnabled && mounted) {
            setState(() {
              _isLocationEnabled = false;
            });
            showSnackBar(
              context: context,
              message: "Please enable location services.",
              color: Colors.red,
            );
          }
          return;
        }
        if (mounted) {
          setState(() {
            _isLocationEnabled = serviceEnabled;
          });
        }
      });

      _locationStreamSubscription =
          Geolocator.getPositionStream().listen((position) async {
        if (mounted) {
          setState(() {
            lat = position.latitude;
            lon = position.longitude;
          });
        }
        if (lat != null && lon != null) {
          await getAddressFromLatLng(lat!, lon!);
          _injectLocationToWebView(position);
        }
      });

      isRequestingLocation = false;
      return 1;
    }
  }

  Future<void> _checkConnectivity() async {
    screenWidth = MediaQuery.of(context).size.width;
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      return;
    }
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) {
        bool previouslyConnected = _isConnected;
        _isConnected = result != ConnectivityResult.none;

        if (_isConnected != previouslyConnected) {
          if (_isConnected) {
            _checkAndRequestLocationServices();
          }
        }
      }
    });
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredClients.value = _allClients;
    } else {
      _filteredClients.value = _allClients.where((client) {
        return client.toLowerCase().contains(query);
      }).toList();
    }
  }

  void _retryGetLocation() async {
    if (lat != null && lon != null) {
      isRequestingLocation = false;
      return;
    }
    const interval = Duration(seconds: 5);
    Timer.periodic(interval, (timer) async {
      serviceEnabled = await location.serviceEnabled();
      if (serviceEnabled) {
        LocationData? currentLocation = await location.getLocation();
        timer.cancel();
        lat = currentLocation.latitude;
        lon = currentLocation.longitude;

        getAddressFromLatLng(lat!, lon!);
      }
    });
  }

  Future<void> getAddressFromLatLng(double lat, double lon) async {
    if (address != 'Searching...') {
      return;
    }

    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(lat, lon);
      geocoding.Placemark place = placemarks[0];

      address =
          "${place.administrativeArea}, ${place.subAdministrativeArea}, ${place.subLocality}";
      if (place.administrativeArea == "" ||
          place.administrativeArea == "Unnamed Road") {
        address =
            "${place.subAdministrativeArea}, ${place.subLocality}, ${place.postalCode}";
      }
      if (place.subAdministrativeArea == "" ||
          place.subAdministrativeArea == "Unnamed Road") {
        address =
            "${place.locality}, ${place.subLocality}, ${place.postalCode}";
      }
    } catch (e) {
      address = "Unable to get location";
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _injectLocationToWebView(Position locationData) async {
    if (lat != null && lon != null) {
      return;
    }
    String jsCode = '''
      navigator.geolocation.getCurrentPosition = function(success, error, options) {
        var position = {
          coords: {
            latitude: ${locationData.latitude},
            longitude: ${locationData.longitude},
            accuracy: ${locationData.accuracy},
            altitude: ${locationData.altitude},
            heading: ${locationData.heading},
            speed: ${locationData.speed}
          },
          timestamp: ${locationData.timestamp}
        };
        success(position);
      };
    ''';
    lat = locationData.latitude;
    lon = locationData.longitude;

    await getAddressFromLatLng(lat!, lon!);

    webViewController?.evaluateJavascript(source: jsCode);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationServiceTimer?.cancel();
    _timer?.cancel();
    _inactivityTimer?.cancel();
    _connectivitySubscription.cancel();
    _searchController.dispose();
    _locationStreamSubscription?.cancel();
    _filteredClients.dispose();
    _attType.dispose();
    _isObscure.dispose();
    _isLocationDialogOpen.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
    userNameController = TextEditingController(text: username);

    final url = Uri.parse('$initUrl/api/get_client_details');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData["status"] == "success") {
        final List<dynamic> clientsData = responseData["data"];
        _allClients.clear();
        _clientIds.clear();
        allLat.clear();
        allLon.clear();
        allCoverage.clear();
        for (var client in clientsData) {
          _clientIds.add(client["id"]);
          _allClients.add(
            "${client["comp_name"]} | ${client["comp_address"]} | ${client["comp_phone"]}",
          );
          allLat.add(_parseDouble(client["latitude"]));
          allLon.add(_parseDouble(client["longitude"]));
          allCoverage.add(_parseDouble(client["coverage_area"]));
        }
      }
    } catch (e) {
      print('Error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  void _showLocationServiceDialog() {
    if (_isLocationDialogOpen.value) return;
    _isLocationDialogOpen.value = true;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.location_off,
                color: Colors.red,
                size: 25,
              ),
              SizedBox(width: 10),
              Text(
                'Location Services Off',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Your device location service is turned off. Please enable it to submit attendance.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _isLocationDialogOpen.value = false;
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () async {
                serviceEnabled = await location.requestService();
                _isLocationDialogOpen.value = false;
                Navigator.of(context).pop();
              },
              child: const Text(
                'Turn On',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  void openAppSettingsDialog() {
    if (_isDialogOpen ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      // Avoid showing the dialog if the app is in the background
      return;
    }
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 25,
              ),
              Text(
                ' Permission Required !!!',
                style: TextStyle(
                  fontSize: screenWidth > 600 ? 25 : 18,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Please open app settings to grant precise location permission.',
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _isDialogOpen = false;

                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                _isDialogOpen = false;

                Navigator.of(context).pop();

                await openAppSettings();
                _onRefresh();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login(String username, String password) async {
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
        if (!_isLocationEnabled) {
          showSnackBar(
            context: context,
            message: "Please enable location.",
            color: Colors.red,
          );
          await _checkAndRequestLocationServices();

          return;
        }
        if (!_isChecked.value) {
          showSnackBar(
            context: context,
            message: "You must agree to our terms and policies.",
            color: Colors.red,
          );
          return;
        }
        await _checkAndRequestLocationServices();
        String remarks = remarksController.text.trim();

        final newAtt = AttendanceModel(
          email: username,
          password: password,
          attType: _attType.value,
          remarks: remarks,
          gpsLatitude: lat!,
          gpsLongitude: lon!,
          address: address,
        );
        sendAttendance(newAtt, initUrl);
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
      debugPrint("Login error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkAndRequestLocationServices();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: DefaultTabController(
          length: token != '' && token != null ? 2 : 0, // write no of tabs
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: const Color(0xFF346CB0),
              elevation: 0,
              title: const Text(
                'Mobile Attendance',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                ),
              ),
              bottom: token != '' && token != null
                  ? const TabBar(
                      tabs: [
                        Tab(
                          text: 'Attendance',
                        ),
                        Tab(
                          text: 'Client Checkin',
                        ),
                      ],
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      isScrollable: false,
                      unselectedLabelColor: Color.fromARGB(255, 226, 226, 226),
                    )
                  : null,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: token != '' && token != null
                        ? TabBarView(
                            children: [
                              _buildAttendanceForm(1),
                              _buildAttendanceForm(2),
                            ],
                          )
                        : _buildAttendanceForm(1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceForm(int tab) {
    String mapHtml = '''
        <!DOCTYPE html>
        <html>
        <head>
            <title>Map</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
            <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
            <style>
                #map {
                    height: 200px;
                    /* Fixed height for testing */
                    width: 100%;
                }
            </style>
        </head>

        <body>
            <div id="map"></div>
            <script>
                // Initialize the map
                var map = L.map('map').setView([${lat ?? 0}, ${lon ?? 0}], 16);

                // Add tile layer
                L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    maxZoom: 19,
                    attribution: 'Map data © OpenStreetMap contributors                         .  '
                }).addTo(map).on('error', function (e) {
                    console.error('Tile Layer Error:', e);
                });

                // Add marker
                L.marker([${lat ?? 0}, ${lon ?? 0}]).addTo(map);
            
                map.panTo([${lat ?? 0}, ${lon ?? 0}]);
                // Debugging information
                console.log('Map initialized at latitude: ${lat ?? 0}, longitude: ${lon ?? 0}');
            </script>
        </body>

        </html>
        ''';

    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              child: ElevatedButton(
                onPressed: () {
                  _showMap.value = !_showMap.value;
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  minimumSize: const Size(double.infinity, 30),
                  backgroundColor: const Color(0xFF0286D0),
                  padding: const EdgeInsets.all(1),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("  "),
                      Expanded(
                        child: address == 'Searching...'
                            ? const Row(
                                children: [
                                  Text(
                                    '   Address:  ',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white),
                                  ),
                                  Center(
                                    child: SizedBox(
                                      width: 13,
                                      height: 13,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 0.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  const Text("   "),
                                  Flexible(
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Address: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            address,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Row(
                        children: [
                          Icon(
                            _showMap.value
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            size: 27,
                            color: Colors.white,
                          ),
                          const Text("    "),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: _showMap,
              builder: (context, showMap, child) {
                return showMap
                    ? SizedBox(
                        height: 180,
                        child: (lat != null || lon != null)
                            ? InAppWebView(
                                initialData: InAppWebViewInitialData(
                                  data: mapHtml,
                                  mimeType: 'text/html',
                                  encoding: 'utf-8',
                                ),
                                onWebViewCreated:
                                    (InAppWebViewController controller) {
                                  webViewController = controller;
                                },
                                initialSettings: InAppWebViewSettings(
                                  mediaPlaybackRequiresUserGesture: false,
                                  allowsInlineMediaPlayback: true,
                                  iframeAllow: "camera; microphone",
                                  cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
                                ),
                              )
                            : Center(
                                child: TickerMode(
                                  enabled:
                                      ModalRoute.of(context)?.isCurrent ?? true,
                                  child: CustomLoadingIndicator(),
                                ),
                              ),
                      )
                    : Transform.translate(
                        offset: const Offset(0, 0),
                      );
              },
            ),
            Transform.translate(
              offset: Offset(0, tab == 2 ? -35 : -20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        tab == 2
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Form(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 30),
                                        SizedBox(
                                          height: 45,
                                          child: TextFormField(
                                            controller: _searchController,
                                            decoration: InputDecoration(
                                              focusedBorder:
                                                  const OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(8.0)),
                                                borderSide: BorderSide(
                                                  color: Colors.orange,
                                                  width: 2.0,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 7),
                                              suffixIcon: IconButton(
                                                icon: Icon(_isNotEmpty
                                                    ? Icons.close
                                                    : Icons.search),
                                                onPressed: () {
                                                  if (_isNotEmpty) {
                                                    _searchController.clear();
                                                    _filterClients();
                                                  }
                                                },
                                              ),
                                              hintText: 'Search Clients',
                                              hintStyle:
                                                  const TextStyle(fontSize: 14),
                                              border: const OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(8.0)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        if (_filteredClients.value.isNotEmpty)
                                          ValueListenableBuilder(
                                              valueListenable: _filteredClients,
                                              builder: (context,
                                                  filteredClients, child) {
                                                return Container(
                                                  height:
                                                      filteredClients.length > 3
                                                          ? 171
                                                          : filteredClients
                                                                  .length *
                                                              57,
                                                  color: Colors.grey[200],
                                                  child: ListView.builder(
                                                    itemCount:
                                                        filteredClients.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      List<String> parts =
                                                          filteredClients[index]
                                                              .split(' | ');

                                                      return ListTile(
                                                        title: RichText(
                                                          text: TextSpan(
                                                            children: [
                                                              TextSpan(
                                                                text: parts[0],
                                                                style: const TextStyle(
                                                                    color: Color
                                                                        .fromARGB(
                                                                            255,
                                                                            0,
                                                                            136,
                                                                            255)),
                                                              ),
                                                              const TextSpan(
                                                                text: " | ",
                                                                style: TextStyle(
                                                                    color: Color
                                                                        .fromARGB(
                                                                            255,
                                                                            0,
                                                                            0,
                                                                            0)),
                                                              ),
                                                              TextSpan(
                                                                text: parts[1],
                                                                style: const TextStyle(
                                                                    color: Color
                                                                        .fromARGB(
                                                                            255,
                                                                            255,
                                                                            119,
                                                                            0)),
                                                              ),
                                                              const TextSpan(
                                                                text: " | ",
                                                                style: TextStyle(
                                                                    color: Color
                                                                        .fromARGB(
                                                                            255,
                                                                            0,
                                                                            0,
                                                                            0)),
                                                              ),
                                                              TextSpan(
                                                                text: parts[2],
                                                                style: const TextStyle(
                                                                    color: Color
                                                                        .fromARGB(
                                                                            255,
                                                                            98,
                                                                            0,
                                                                            255)),
                                                              ),
                                                            ],
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12),
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          FocusScope.of(context)
                                                              .unfocus();

                                                          _searchController
                                                                  .text =
                                                              filteredClients[
                                                                  index];
                                                          _filteredClients.value
                                                              .clear();
                                                        },
                                                      );
                                                    },
                                                  ),
                                                );
                                              }),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        const SizedBox(height: 14),
                        tab == 1
                            ? Column(
                                children: [
                                  SizedBox(
                                    height: 45,
                                    child: TextFormField(
                                      controller: userNameController,
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 0,
                                          horizontal: 7,
                                        ),
                                        suffixIcon: Icon(Icons.email_outlined),
                                        hintText: 'Username / Email',
                                        hintStyle: TextStyle(fontSize: 12.0),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8.0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8.0)),
                                          borderSide: BorderSide(
                                              color: Colors.orange, width: 2.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 45,
                                    child: ValueListenableBuilder(
                                      valueListenable: _isObscure,
                                      builder: (BuildContext context, value,
                                          Widget? child) {
                                        return TextFormField(
                                          controller: passwordController,
                                          obscureText: _isObscure.value,
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 0, horizontal: 7),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _isObscure.value
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                              ),
                                              onPressed: () {
                                                _isObscure.value =
                                                    !_isObscure.value;
                                              },
                                            ),
                                            hintText: 'Password',
                                            hintStyle:
                                                const TextStyle(fontSize: 12.0),
                                            focusedBorder:
                                                const OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(8.0)),
                                              borderSide: BorderSide(
                                                  color: Colors.orange,
                                                  width: 2.0),
                                            ),
                                            border: const OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(8.0)),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              )
                            : const SizedBox(),
                        const Text(
                          'Attendance Type:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 7),
                        ValueListenableBuilder(
                          valueListenable: _attType,
                          builder: (context, value, child) => Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text(
                                    'CheckIn',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  value: 'CHECKIN',
                                  groupValue: _attType.value,
                                  activeColor: Colors.orange,
                                  onChanged: (String? value) {
                                    _attType.value = "CHECKIN";
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text(
                                    'CheckOut',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  value: 'CHECKOUT',
                                  activeColor: Colors.orange,
                                  groupValue: _attType.value,
                                  onChanged: (String? value) {
                                    _attType.value = "CHECKOUT";
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Stack(
                          children: [
                            TextFormField(
                              controller: remarksController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 7),
                                hintText: 'Remarks',
                                hintStyle: TextStyle(fontSize: 12.0),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8.0)),
                                  borderSide: BorderSide(
                                      color: Colors.orange, width: 2.0),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8.0)),
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 10,
                              right: 10,
                              child: Icon(
                                Icons.mode_edit_rounded,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () async {
                  int result = 1;
                  _retryGetLocation();
                  if (lat == null || lon == null || address == 'Searching...') {
                    try {
                      result = await _checkAndRequestLocationServices();
                    } catch (e) {
                      print("ERROR:- $e");
                    }
                  }

                  if (result == 0) {
                    return;
                  }

                  if (token != "" && token != null) {
                    userNameController = TextEditingController(text: username);
                  }

                  String email = "";
                  email = userNameController.text.trim();

                  String password = passwordController.text.trim();
                  String remarks = remarksController.text.trim();

                  if (tab == 1 && email == "" || password == "") {
                    showSnackBar(
                      context: context,
                      message: "Email or password cannot be empty.",
                      color: Colors.red,
                    );
                    return;
                  }
                  if (!_isLocationEnabled) {
                    showSnackBar(
                      context: context,
                      message: "Please enable location.",
                      color: Colors.red,
                    );
                    await _checkAndRequestLocationServices();

                    return;
                  }

                  if (!_isChecked.value) {
                    showSnackBar(
                      context: context,
                      message: "You must agree to our terms and policies.",
                      color: Colors.red,
                    );
                    return;
                  }
                  FocusScope.of(context).unfocus();
                  await _checkAndRequestLocationServices();

                  if (tab == 1) {
                    final newAtt = AttendanceModel(
                      email: email,
                      password: password,
                      attType: _attType.value,
                      remarks: (remarks == "") ? "" : remarks,
                      gpsLatitude: lat!,
                      gpsLongitude: lon!,
                      address: address,
                    );
                    sendAttendance(newAtt, initUrl);
                  } else {
                    String client = _searchController.text.trim();

                    if (client == "") {
                      showSnackBar(
                        context: context,
                        message: "Please select a client.",
                        color: Colors.red,
                      );
                      return;
                    }
                    for (int i = 0; i < allCoverage.length; i++) {
                      if (_allClients[i] == client) {
                        final distance = Geolocator.distanceBetween(
                          lat!,
                          lon!,
                          allLat[i],
                          allLon[i],
                        );

                        if (distance <= allCoverage[i]) {
                          DateTime now = DateTime.now();
                          String formattedTime =
                              DateFormat('HH:mm:ss').format(now);
                          final newClient = CheckinModel(
                            clientId: _clientIds[i],
                            email: email,
                            password: password,
                            attType: _attType.value,
                            remarks: (remarks == "") ? "" : remarks,
                            gpsLatitude: lat ?? 0,
                            gpsLongitude: lon ?? 0,
                            address: address,
                            client: client,
                            attTime: formattedTime,
                          );
                          submitCheckin(newClient, initUrl);
                        } else {
                          showSnackBar(
                            message: "You are outside the coverage area.",
                            context: context,
                            color: Colors.red,
                          );
                        }
                        break;
                      }
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
                child: Text(
                  tab == 1 ? 'Submit Attendance' : _attType.value,
                  style: const TextStyle(
                    fontFamily: 'inherit',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: token != '' && token != null
                  ? null
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ValueListenableBuilder(
                              valueListenable: _isChecked,
                              builder: (context, value, child) => Checkbox(
                                activeColor: Colors.orange,
                                value: value,
                                onChanged: (bool? value) {
                                  _isChecked.value = value ?? false;
                                },
                              ),
                            ),
                            const Text(
                              "By submitting in you are agreeing to our",
                              style: TextStyle(
                                fontFamily: 'inherit',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Transform.translate(
                          offset: const Offset(0, -9),
                          child: InkWell(
                            child: const Text(
                              'Term and privacy policy',
                              style: TextStyle(
                                color: Colors.blue,
                                fontFamily: 'inherit',
                                fontSize: 16,
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
              child: isBio! && username != null
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
                            'Submit with biometric',
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
          ],
        ),
      ),
    );
  }

  Future<void> sendAttendance(
    AttendanceModel model,
    String initUrl,
  ) async {
    final url = Uri.parse('$initUrl/api/authenticate_user_for_attendance');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(model.toJson());

    try {
      final response = await http.post(url, headers: headers, body: body);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData["status"] == "success") {
        showSnackBar(
          message: responseData["message"],
          context: context,
        );
        // Navigator.pop(context);
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
  }

  Future<void> submitCheckin(
    CheckinModel model,
    String initUrl,
  ) async {
    final url = Uri.parse('$initUrl/api/submit_ot_request');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(model.toJson());

    try {
      final response = await http.post(url, headers: headers, body: body);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData["status"] == "success") {
        showSnackBar(
          message: responseData["message"],
          context: context,
        );
        Navigator.pop(context);
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
  }
}
