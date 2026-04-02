import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ensureInitialized ต้องเรียกก่อนใช้ plugin ทุกตัว
  runApp(const StudentPlannerApp());
}
