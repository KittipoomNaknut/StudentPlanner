import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../core/models/assignment.dart';

class NotificationService {
  // Singleton
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _notifications = FlutterLocalNotificationsPlugin();

  // Android notification channel
  static const _channel = AndroidNotificationDetails(
    'deadline_channel',
    'Deadline Reminders',
    channelDescription: 'Notifications for upcoming assignment deadlines',
    importance: Importance.high,
    priority:   Priority.high,
    icon:       '@mipmap/ic_launcher',
  );

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS:     iosSettings,
      ),
    );

    // ขอ permission บน Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // แจ้งเตือนทันที (สำหรับทดสอบ)
  Future<void> showNow({
    required int    id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id, title, body,
      const NotificationDetails(android: _channel),
    );
  }

  // แจ้งเตือนตามเวลาที่กำหนด
  Future<void> scheduleNotification({
    required int      id,
    required String   title,
    required String   body,
    required DateTime scheduledDate,
  }) async {
    // ถ้าเวลาผ่านไปแล้ว ไม่ต้อง schedule
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Schedule notification สำหรับ assignment
  // แจ้งเตือน 1 วันก่อน deadline
  Future<void> scheduleAssignmentReminder(Assignment a) async {
    final deadline = DateTime.tryParse(a.deadline);
    if (deadline == null || a.id == null) return;

    // 1 วันก่อน deadline เวลา 09:00
    final oneDayBefore = DateTime(
      deadline.year, deadline.month, deadline.day - 1, 9, 0,
    );

    await scheduleNotification(
      id:            a.id! * 10,      // unique id
      title:         '📚 Due Tomorrow',
      body:          '${a.title} is due tomorrow!',
      scheduledDate: oneDayBefore,
    );

    // 3 ชั่วโมงก่อน deadline
    final threeHoursBefore = deadline.subtract(const Duration(hours: 3));
    await scheduleNotification(
      id:            a.id! * 10 + 1,
      title:         '⚠️ Due Soon',
      body:          '${a.title} is due in 3 hours!',
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