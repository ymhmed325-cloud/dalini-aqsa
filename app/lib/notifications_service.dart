import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    try {
      await _plugin.initialize(settings);
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {}
  }

  static Future<void> show(String title, String body) async {
    if (!_ready) await init();
    const android = AndroidNotificationDetails(
      'dalini_channel',
      'إشعارات دليني',
      channelDescription: 'طلبات وتحديثات',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);
    try {
      await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
    } catch (_) {}
  }
}
