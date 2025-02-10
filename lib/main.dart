
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'core/app.dart';
import 'core/config.dart';
import 'core/user_shared_pref.dart';
import 'firebase_options.dart';

UserSharedPrefs usp = UserSharedPrefs();

bool userauth = false;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  _showNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

//   await requestNotificationPermission();

  // Config.setHomeUrl("https://heliosnepal.smarthajiri.com");
  // Config.setHomeUrl("https://manaramhr.xelwel.com");
  // Config.setHomeUrl("https://medibiz.xelwel.com");
  // Config.setHomeUrl("https://digi.smarthajiri.com");
//   Config.setHomeUrl("https://hrm.gmc.edu.np");
  // Config.setHomeUrl("https://grdbl.xelwel.com");
  // Config.setHomeUrl("https://ehpl.xelwel.com");
  // Config.setHomeUrl("https://hris.careerinnepal.com");
  // Config.setHomeUrl("https://manipal.smarthajiri.com");
//   Config.setHomeUrl("https://mediplus.smarthajiri.com/");

// Change login image
  Config.setLoginImage("assets/logo/logo.png");

  // Change Splash Image
  Config.setSplashImage("assets/logo/logo.png");

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_notification');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  void onNotificationTap(NotificationResponse notificationResponse) async {
    if (notificationResponse.payload != null) {
      print("NOTIFICATION CLICKES");
      // Navigate to the notifications page
    }
  }

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onNotificationTap,
  );

  Connectivity().onConnectivityChanged.listen((result) {
    Config.hasInternet(result.first != ConnectivityResult.none);
  });

  await FirebaseMessaging.instance.subscribeToTopic('0');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showNotification(message);
  });

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    const MyApp(),
  );
}

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
}

void _showNotification(RemoteMessage message) async {
  if (message.notification == null) {
    return;
  }
  String? title = message.notification?.title;
  String? body = message.notification?.body;
  String? imageUrl = message.notification?.android?.imageUrl;
  String notificationDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  String? largeIconPath;
  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/largeIcon.png';
        final file = File(imagePath);
        file.writeAsBytesSync(response.bodyBytes);
        largeIconPath = imagePath;
      }
    } catch (e) {
      print("Error downloading image: $e");
    }
  }

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    channelDescription: 'channel_description',
    importance: Importance.max,
    priority: Priority.high,
    largeIcon:
        largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
    styleInformation: const DefaultStyleInformation(true, true),
  );
  final platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    "$body",
    platformChannelSpecifics,
    payload: 'item x',
  );
}
