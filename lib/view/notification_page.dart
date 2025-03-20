import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:refresh/refresh.dart';
import 'package:smarthajiri/core/config.dart';
import 'package:smarthajiri/core/loading_indicator.dart';
import 'package:smarthajiri/core/user_shared_pref.dart';
import 'package:smarthajiri/model/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  final ValueNotifier<List<NotificationItem>> _notificationsNotifier =
      ValueNotifier([]);

  final ValueNotifier<bool> _isLoadingNoifier = ValueNotifier<bool>(true);
  UserSharedPrefs usp = UserSharedPrefs();
  String? token;
  String initUrl = Config.getHomeUrl();
  int? empId;
  List<bool> isExpanded = [];
  final ScrollController _scrollController = ScrollController();

  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  void initState() {
    super.initState();
    onRefresh();
  }

  Future<List<NotificationItem>> getNoti() async {
    token = await usp.getToken();
    final url = Uri.parse('$initUrl/api/v1/get_notification');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(url, headers: headers);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData["status"] == "success") {
        return responseData["data"].map<NotificationItem>((notification) {
          String date = notification['postdatead'].replaceAll('/', '-');
          return NotificationItem(
            id: int.parse(notification['id']),
            empid: int.parse(notification['empid']),
            title: notification['subject'],
            message: notification['description'],
            date: DateTime.parse(date),
            read: notification['status'] == 'R',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    return [];
  }

  Future<void> updateNoti(int id, int empid) async {}

  void onRefresh() async {
    // await Future.delayed(const Duration(milliseconds: 1000));
    _notificationsNotifier.value = await getNoti();
    isExpanded = List.filled(_notificationsNotifier.value.length, false);
    _isLoadingNoifier.value = false;
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    // final today = DateTime.now();
    // final tomorrow = DateTime(today.year, today.month, today.day + 1);
    // final yesterday = DateTime(today.year, today.month, today.day - 1);

    // final todayNotifications = _notificationsNotifier.value
    //     .where((n) =>
    //         n.date.isAfter(DateTime(today.year, today.month, today.day)) &&
    //         n.date.isBefore(tomorrow))
    //     .toList();

    // final yesterdayNotifications = _notificationsNotifier.value
    //     .where((n) =>
    //         n.date.isAfter(
    //             DateTime(yesterday.year, yesterday.month, yesterday.day)) &&
    //         n.date.isBefore(DateTime(today.year, today.month, today.day)))
    //     .toList();

    // final earlierNotifications = _notificationsNotifier.value
    //     .where((n) => n.date
    //         .isBefore(DateTime(yesterday.year, yesterday.month, yesterday.day)))
    //     .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF346CB0),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: onRefresh,
        child: ValueListenableBuilder(
          valueListenable: _isLoadingNoifier,
          builder: (_, isLoading, __) {
            return isLoading
                ? Center(
                    child: TickerMode(
                      enabled: ModalRoute.of(context)?.isCurrent ?? true,
                      child: CustomLoadingIndicator(),
                    ),
                  )
                : ValueListenableBuilder<List<NotificationItem>>(
                    valueListenable: _notificationsNotifier,
                    builder: (context, notifications, child) =>
                        ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: notifications.length,
                      itemBuilder: (_, index) {
                        return _buildNotificationTile(
                            notifications[index], index);
                      },
                    ),
                  );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification, int index) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () async {
          isExpanded[index] = !isExpanded[index];

          token = await usp.getToken();
          final url = Uri.parse('$initUrl/api/v1/update_notification');

          final headers = {
            'Authorization': 'Bearer $token',
          };
          final body = {
            'id': "${notification.id}",
          };
          try {
            final response = await http.post(url, headers: headers, body: body);

            final Map<String, dynamic> responseData = jsonDecode(response.body);

            if (responseData["status"] == "success") {
              _notificationsNotifier.value[index] =
                  notification.copyWith(read: true);
            }
          } catch (e) {
            debugPrint('Error occurred: $e');
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: notification.read
                ? const Color.fromARGB(255, 255, 255, 255)
                : const Color.fromARGB(255, 158, 158, 158),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12.0),
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.notifications,
                color: notification.read
                    ? const Color.fromARGB(255, 153, 153, 153)
                    : const Color.fromARGB(255, 34, 149, 243),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    isExpanded[index]
                        ? Html(data: notification.message)
                        : _buildTruncatedHtml(notification.message),
                    const SizedBox(height: 5),
                    Text(
                      '${notification.date.toLocal()}'.split(' ')[0],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 158, 158, 158),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildTruncatedHtml(String htmlData) {
  final plainText = _convertHtmlToPlainText(htmlData);
  final truncatedText =
      plainText.length > 100 ? '${plainText.substring(0, 100)}...' : plainText;

  return Text(
    truncatedText,
    style: const TextStyle(
      fontSize: 14,
      color: Color.fromARGB(255, 117, 117, 117),
    ),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );
}

String _convertHtmlToPlainText(String htmlData) {
  final document = html_parser.parse(htmlData);
  return document.body?.text ?? '';
}
