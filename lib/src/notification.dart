import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';
import 'package:flutter/material.dart';
import 'model/notification_model.dart';

class NotificationHelper {

  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  FlutterLocalNotificationsPlugin _fln;

  final BehaviorSubject<ReceivedNotification>
      _didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();

  var _initializationSettings;

  NotificationHelper._internal() {
    _init();
  }

  _init() async {
    _fln = FlutterLocalNotificationsPlugin();
    if (Platform.isIOS) {
      _requestIOSPermissions();
    }
    _initializePlatformSpecifics();
  }

  _initializePlatformSpecifics() {
    var initializationSettingsAndroid =
        AndroidInitializationSettings(
          "ic_launcher"
        );
    var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        ReceivedNotification receivedNotification = ReceivedNotification(
            id: id, title: title, body: body, payload: payload);
        _didReceiveLocalNotificationSubject.add(receivedNotification);
      },
    );
    _initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
  }

  void _requestIOSPermissions() {
    _fln
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  _setListenerForLowerVersions(Function onNotificationInLowerVersions) {
    _didReceiveLocalNotificationSubject.listen((receivedNotification) {
      onNotificationInLowerVersions(receivedNotification);
    });
  }

  setOnNotificationClick(Function(String) onNotificationClick) async {
    await _fln.initialize(_initializationSettings,
        onSelectNotification: (String payload) async {
      onNotificationClick(payload);
    });
  }

  Future<void> showNotification(
      {@required NotificationModel notification,
      @required NotificationChannel channel}) async {
    var iosChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics =
        NotificationDetails(channel.toDetail(), iosChannelSpecifics);
    await _fln.show(notification.id, notification.title, notification.body,
        platformChannelSpecifics,
        payload: notification.payload);
  }

  Future<void> createNotificationChannel(
      {@required AndroidNotificationChannel notificationChannel}) async {
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(notificationChannel);
  }

  Future<void> deleteNotificationChannel({@required String channelId}) async {
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel(channelId);
  }

  Future<void> cancelAllNotifications() async {
    await _fln.cancelAll();
  }

  Future<void> cancelNotificationById({@required int id})async {
    await _fln.cancel(id);
  }

  Future<List<NotificationModel>> checkPendingNotificationRequests() async {
    var pendingRequests = await _fln.pendingNotificationRequests();
    return pendingRequests
        .map((e) => NotificationModel(
            id: e.id, title: e.title, body: e.body, payload: e.payload))
        .toList();
  }
}

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });
}

extension _channelToDetail on NotificationChannel {
  AndroidNotificationDetails toDetail() {
    return AndroidNotificationDetails(
      this.channelId,
      this.channelName,
      this.channelDescription,
      icon: "ic_launcher"
    );
  }
}

extension on AndroidNotificationChannel {
  NotificationChannel toChannel(){
    return NotificationChannel(
      channelId: this.id,
      channelName: this.name,
      channelDescription: this.description
    );
  }
}

