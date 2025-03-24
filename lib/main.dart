import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:smarthajiri/core/app.dart';
import 'package:smarthajiri/core/config.dart';
import 'package:smarthajiri/firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  _showNotification(message);
}

const String channelId = "channel_id";
const String channelName = "channel_name";
const String channelDescription = "channel_description";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.instance.subscribeToTopic('jff');
  FirebaseMessaging.onMessage.listen(_showNotification);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // await requestNotificationPermission();

  Config.setHomeUrl("https://heliosnepal.smarthajiri.com");
  // Config.setHomeUrl("https://hris.careerinnepal.com");
  // Config.setHomeUrl("https://manaramhr.xelwel.com");
  // Config.setHomeUrl("https://medibiz.xelwel.com");
  // Config.setHomeUrl("https://digi.smarthajiri.com");
  // Config.setHomeUrl("https://hrm.gmc.edu.np");
  // Config.setHomeUrl("https://grdbl.xelwel.com");
  // Config.setHomeUrl("https://ehpl.xelwel.com");
  // Config.setHomeUrl("https://manipal.smarthajiri.com");
  // Config.setHomeUrl("https://mediplus.smarthajiri.com/");

  // Change login image
  Config.setLoginImage("assets/logo/logo.png");

  // Change Splash Image
  Config.setSplashImage("assets/logo/logo.png");

  // App Name and version
  Config.setApkName("HeliosNepal");
  Config.setAppVersion("3.2.8");

  Future.delayed(Duration(seconds: 2), () {
    Connectivity().onConnectivityChanged.listen((result) {
      Config.hasInternet(result.first != ConnectivityResult.none);
    });
  });
  // await initializeNotifications();

  runApp(const MyApp());
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_notification');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (notificationResponse) async {
      if (notificationResponse.payload != null) {
        debugPrint("Notification clicked!");
        // Navigate to the notifications page
      }
    },
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

Future<void> _showNotification(RemoteMessage message) async {
  if (message.notification == null) return;

  final title = message.notification!.title ?? "New Notification";
  final body = message.notification!.body ?? "Tap to view details";
  final imageUrl = message.notification?.android?.imageUrl;

  String? largeIconPath;
  if (imageUrl != null && imageUrl.isNotEmpty) {
    largeIconPath = await compute(_downloadImage, imageUrl);
  }

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: channelDescription,
    importance: Importance.max,
    priority: Priority.high,
    largeIcon:
        largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
    styleInformation: const DefaultStyleInformation(true, true),
  );

  final platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: 'item_x',
  );
}

Future<String?> _downloadImage(String imageUrl) async {
  return await compute(_fetchImage, imageUrl);
}

Future<String?> _fetchImage(String imageUrl) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/largeIcon.png';
      final file = File(imagePath);
      await file.writeAsBytes(response.bodyBytes);
      return imagePath;
    }
  } catch (e) {
    debugPrint("Error downloading image: $e");
  }
  return null;
}
