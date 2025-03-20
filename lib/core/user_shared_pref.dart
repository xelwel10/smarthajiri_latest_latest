import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSharedPrefs {
  static const _storage = FlutterSecureStorage();
  static const _passwordKey = 'password';
  static const _notificationsKey = 'notifications';

  bool isTokenExpired(String token) {
    return JwtDecoder.isExpired(token);
  }

  deleteToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }

  Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken') ?? '';
  }

  Future<void> setUsername(String u) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', u);
  }

  Future<String?> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<String> getPassword() async {
    return await _storage.read(key: _passwordKey) ?? '';
  }

  Future<void> setPassword(String p) async {
    await _storage.write(key: _passwordKey, value: p);
  }

  Future<void> setBio(bool bio) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBioEnabled', bio);
  }

  Future<bool?> getBio() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isBioEnabled') ?? false;
  }

  Future<void> setLogged(bool logged) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLogged', logged);
  }

  Future<bool?> getLogged() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLogged') ?? false;
  }

  Future<void> setNotifications(
      List<Map<String, dynamic>> notifications) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String notificationsJson = jsonEncode(notifications);
    await prefs.setString(_notificationsKey, notificationsJson);
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? notificationsJson = prefs.getString(_notificationsKey);

    List<dynamic> decodedJson = jsonDecode(notificationsJson!);
    return List<Map<String, dynamic>>.from(decodedJson);
  }

  Future<void> addNotification(String? title, String? message) async {
    List<Map<String, dynamic>> notifications = await getNotifications();

    Map<String, dynamic> newNotification = {
      'title': title,
      'message': message,
      'date': DateTime.now().toIso8601String(),
      'read': false
    };

    notifications.insert(0, newNotification);

    await setNotifications(notifications);
  }

  Future<void> markNotificationAsRead(int index) async {
    List<Map<String, dynamic>> notifications = await getNotifications();

    if (index >= 0 && index < notifications.length) {
      notifications[index]['read'] = true;
      await setNotifications(notifications);
    }
  }
}
