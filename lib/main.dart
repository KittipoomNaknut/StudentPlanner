import 'package:flutter/material.dart';
import 'app.dart';
import 'features/notification/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService.instance.initialize();

  runApp(const StudentPlannerApp());
}
