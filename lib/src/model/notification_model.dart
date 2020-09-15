import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationModel {
  int id;
  String title;
  String body;
  String payload;

  NotificationModel({this.id, this.title, this.body, this.payload});

  NotificationModel.fromMessage(Map<String, dynamic> message) {
    this.title = message['notification']['title'];
    this.body = message['notification']['body'];
    var payload = message['data']['payload'];
    this.payload = payload ?? 'default';
    this.id = message['data']['id'] ?? 12;
  }
}

class NotificationChannel {
  final String channelId;
  final String channelName;
  final String channelDescription;

  NotificationChannel(
      {this.channelId, this.channelName, this.channelDescription});
}
