import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background message: ${message.notification?.title}");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print("Notification tapped: ${details.payload}");
      },
    );

    // Handle foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground FCM: ${message.notification?.title}");
      _showSOSNotification(
        message.notification?.title ?? '🚨 SOS Alert',
        message.notification?.body ?? 'New emergency request',
      );
    });

    // Handle notification tap when app in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification opened app: ${message.data}");
    });
  }

  // Subscribe driver to FCM topic + save token
  static Future<void> subscribeDriver() async {
    await FirebaseMessaging.instance.subscribeToTopic('sos_drivers');
    print("Driver subscribed to sos_drivers topic");

    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('driver_tokens')
          .doc('active_driver')
          .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()});
      print("FCM Token saved: $token");
    }
  }

  // Persistent foreground service notification — keeps app alive in background
  static Future<void> startForegroundService() async {
    await _localNotifications.show(
      999,
      'Ambulance Driver',
      'Listening for emergency requests...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'foreground_channel',
          'Driver Service',
          channelDescription: 'Keeps driver app alive for SOS alerts',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true, // cannot be dismissed
          playSound: false,
          enableVibration: false,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
    print("Foreground service notification started");
  }

  // Called from RequestProvider when new SOS arrives
  static Future<void> showLocalSOSNotification(
    String? name,
    String? phone,
  ) async {
    await _showSOSNotification(
      '🚨 Emergency SOS Request!',
      'Patient: ${name ?? "Unknown"} | Phone: ${phone ?? "Unknown"}',
    );
  }

  static Future<void> _showSOSNotification(String title, String body) async {
    await _localNotifications.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sos_channel',
          'SOS Alerts',
          channelDescription: 'Emergency SOS notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
