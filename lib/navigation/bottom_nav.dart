import 'package:flutter/material.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/assignment/assignment_screen.dart';
import '../features/grade/grade_screen.dart';
//import '../features/note/note_screen.dart';
import '../features/subject/subject_screen.dart'; // TEMP

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  // สร้างครั้งเดียว ไม่ rebuild เมื่อเปลี่ยน tab
  final List<Widget> _screens = const [
    DashboardScreen(),
    ScheduleScreen(),
    AssignmentScreen(),
    GradeScreen(),
    //NoteScreen(),
    SubjectScreen(), // TEMP
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // IndexedStack แสดง screen ที่ active แต่ทุก screen ยังอยู่ใน memory
        // ต่างจาก if/else ที่จะ rebuild ทุกครั้ง
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.grade_outlined),
            selectedIcon: Icon(Icons.grade),
            label: 'Grades',
          ),
          // NavigationDestination(
          //   icon: Icon(Icons.note_outlined),
          //   selectedIcon: Icon(Icons.note),
          //   label: 'Notes',
          // ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Subjects',
          ),
        ],
      ),
    );
  }
}
