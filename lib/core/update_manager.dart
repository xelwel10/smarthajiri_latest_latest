import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smarthajiri/core/auto_format_text.dart';
import 'package:smarthajiri/core/config.dart';
import 'package:url_launcher/url_launcher.dart';

const String checkUrl =
    'https://raw.githubusercontent.com/Xelwel10/releases/main/checkUpdate.json';
const String releasesUrl =
    'https://api.github.com/repos/Xelwel10/releases/releases/latest';
String downloadUrlKey = 'url${Config.getApkName()}';
String downloadFilename = '${Config.getApkName()}.apk';

String appVersion = Config.getAppVersion();

late Map<String, dynamic> map;
late String latestVersion;
late Map<String, dynamic> releasesResponse;

Future<void> checkAppUpdates() async {
  try {
    final response = await http.get(Uri.parse(checkUrl));

    if (response.statusCode != 200) {
      return;
    }

    map = json.decode(response.body) as Map<String, dynamic>;
    latestVersion = map['version${Config.getApkName()}'].toString();
    
    if (latestVersion == 'null') {
      return;
    }

    if (!isLatestVersionHigher(appVersion, latestVersion)) {
      return;
    }
    final releasesRequest = await http.get(Uri.parse(releasesUrl));

    if (releasesRequest.statusCode != 200) {
      return;
    }

    releasesResponse =
        json.decode(releasesRequest.body) as Map<String, dynamic>;
    Config.setupdateAvailable(true);
  } catch (e) {
    debugPrint('Error in checkAppUpdates $e');
  }
}

Future<void> showAppUpdateDialog(BuildContext context) async {
  if (Config.isUpdateDialogopen()) {
    return;
  }
  Config.setIsUpdateDialogopen(true);
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Update is available",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'V$latestVersion',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height / 2.14,
              ),
              child: SingleChildScrollView(
                child: AutoFormatText(text: releasesResponse['body']),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  Config.setIsUpdateDialogopen(false);
                  Navigator.pop(context);
                },
                child: Text(
                  "CANCEL",
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  Config.setIsUpdateDialogopen(false);

                  getDownloadUrl(map).then(
                    (url) =>
                        {launchURL(Uri.parse(url)), Navigator.pop(context)},
                  );
                },
                child: Text(
                  "DOWNLOAD",
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

Future<void> launchURL(Uri url) async {
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}

bool isLatestVersionHigher(String appVersion, String latestVersion) {
  final parsedAppVersion = appVersion.split('.');
  final parsedAppLatestVersion = latestVersion.split('.');
  final length = parsedAppVersion.length > parsedAppLatestVersion.length
      ? parsedAppVersion.length
      : parsedAppLatestVersion.length;
  for (var i = 0; i < length; i++) {
    final value1 =
        i < parsedAppVersion.length ? int.parse(parsedAppVersion[i]) : 0;
    final value2 = i < parsedAppLatestVersion.length
        ? int.parse(parsedAppLatestVersion[i])
        : 0;
    if (value2 > value1) {
      return true;
    } else if (value2 < value1) {
      return false;
    }
  }

  return false;
}

Future<String> getDownloadUrl(Map<String, dynamic> map) async {
  final url = map[downloadUrlKey].toString();

  return url;
}
