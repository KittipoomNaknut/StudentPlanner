// lib/features/notification/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../core/models/assignment.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _notifications = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationDetails(
    'deadline_channel',
    'Deadline Reminders',
    channelDescription: 'Notifications for upcoming assignment deadlines',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {},
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }

  // แสดง notification ทันที (สำหรับทดสอบ)
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(android: _channel),
    );
  }

  // Schedule notification ตามเวลาที่กำหนด
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Schedule notification สำหรับ assignment
  Future<void> scheduleAssignmentReminder(Assignment a) async {
    final deadline = DateTime.tryParse(a.deadline);
    if (deadline == null || a.id == null) return;

    // แจ้งเตือน 1 วันก่อน deadline เวลา 09:00
    final oneDayBefore = DateTime(
      deadline.year,
      deadline.month,
      deadline.day - 1,
      9,
      0,
    );
    await scheduleNotification(
      id: a.id! * 10,
      title: '📚 Due Tomorrow',
      body: '${a.title} is due tomorrow!',
      scheduledDate: oneDayBefore,
    );

    // แจ้งเตือน 3 ชั่วโมงก่อน deadline
    final threeHoursBefore = deadline.subtract(const Duration(hours: 3));
    await scheduleNotification(
      id: a.id! * 10 + 1,
      title: '⚠️ Due Soon',
      body: '${a.title} is due in 3 hours!',
      scheduledDate: threeHoursBefore,
    );
  }

  // ยกเลิก notification ของ assignment
  Future<void> cancelAssignmentReminder(int assignmentId) async {
    await _notifications.cancel(assignmentId * 10);
    await _notifications.cancel(assignmentId * 10 + 1);
  }

  // ยกเลิกทั้งหมด
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
