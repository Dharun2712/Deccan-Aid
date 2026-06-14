import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('[Notification] Tapped: ${response.payload}');
      },
    );

    // Create notification channels for Android
    const AndroidNotificationChannel ambulanceChannel = AndroidNotificationChannel(
      'ambulance_channel',
      'Ambulance Updates',
      description: 'Notifications for ambulance status and location updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const AndroidNotificationChannel locationChannel = AndroidNotificationChannel(
      'ambulance_location_channel',
      'Ambulance Location',
      description: 'Live ambulance location updates',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    // Emergency alert channel - highest priority for screen-off and background alerts
    const AndroidNotificationChannel emergencyChannel = AndroidNotificationChannel(
      'emergency_alert_channel',
      'Emergency Alerts',
      description: 'High priority emergency alerts that work when screen is off',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
    );

    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      // Create channels
      await android.createNotificationChannel(ambulanceChannel);
      await android.createNotificationChannel(locationChannel);
      await android.createNotificationChannel(emergencyChannel);
      
      // Request permissions for Android 13+
      await android.requestNotificationsPermission();
      
      print('[NotificationService] Channels created and permissions requested');
    }

    _initialized = true;
    print('[NotificationService] Initialized successfully');
  }

  Future<void> showDriverAcceptedNotification({
    required String driverName,
    required String vehicle,
    required String eta,
    required String distance,
  }) async {
    await initialize();
    
    print('[NotificationService] Showing driver accepted notification');
    print('[NotificationService] Driver: $driverName, Vehicle: $vehicle, ETA: $eta, Distance: $distance');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ambulance_channel',
      'Ambulance Updates',
      channelDescription: 'Notifications for ambulance status and location updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'Driver $driverName is on the way in $vehicle\n'
        '📍 Distance: $distance\n'
        '⏱️ ETA: $eta\n\n'
        'Track ambulance location in real-time on the map.',
        htmlFormatBigText: true,
        contentTitle: '🚑 Ambulance Assigned!',
        htmlFormatContentTitle: true,
        summaryText: 'Smart Ambulance',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        0,
        '🚑 Ambulance Assigned!',
        'Driver $driverName is on the way in $vehicle • ETA: $eta',
        details,
        payload: 'driver_accepted',
      );
      print('[NotificationService] Notification shown successfully');
    } catch (e) {
      print('[NotificationService] Error showing notification: $e');
    }
  }

  Future<void> showAmbulanceLocationUpdate({
    required String distance,
    required String eta,
  }) async {
    await initialize();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ambulance_location_channel',
      'Ambulance Location',
      channelDescription: 'Live ambulance location updates',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: false,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        '📍 Distance: $distance\n⏱️ ETA: $eta',
        htmlFormatBigText: true,
        contentTitle: '🚑 Ambulance En Route',
        htmlFormatContentTitle: true,
      ),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      1,
      '🚑 Ambulance En Route',
      'Distance: $distance • ETA: $eta',
      details,
      payload: 'location_update',
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
