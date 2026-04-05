import 'package:flutter/material.dart';

/// InheritedWidget that provides Thai/English localization strings
/// to the entire widget tree.
class AppStrings extends InheritedWidget {
  final String lang; // 'th' or 'en'

  const AppStrings({
    super.key,
    required this.lang,
    required super.child,
  });

  static AppStrings of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppStrings>();
    assert(result != null, 'No AppStrings found in context');
    return result!;
  }

  bool get _th => lang == 'th';

  // ── NAVIGATION ──────────────────────────────────────────────
  String get navHome     => _th ? 'หน้าหลัก' : 'Home';
  String get navSchedule => _th ? 'ตาราง'    : 'Schedule';
  String get navTasks    => _th ? 'งาน'       : 'Tasks';
  String get navGrades   => _th ? 'เกรด'      : 'Grades';
  String get navNotes    => _th ? 'บันทึก'    : 'Notes';

  // ── COMMON ──────────────────────────────────────────────────
  String get add         => _th ? 'เพิ่ม'      : 'Add';
  String get edit        => _th ? 'แก้ไข'     : 'Edit';
  String get delete      => _th ? 'ลบ'         : 'Delete';
  String get cancel      => _th ? 'ยกเลิก'    : 'Cancel';
  String get save        => _th ? 'บันทึก'    : 'Save';
  String get today       => _th ? 'วันนี้'     : 'Today';
  String get unknown     => _th ? 'ไม่ทราบ'   : 'Unknown';
  String get due         => _th ? 'กำหนดส่ง'  : 'Due';
  String get deleteTitle => _th ? 'ยืนยันการลบ' : 'Delete';
  String get deleteBody  => _th ? 'การดำเนินการนี้ไม่สามารถย้อนกลับได้' : 'This action cannot be undone.';
  String get confirmDelete => _th ? 'ลบ'       : 'Delete';
  String get noData      => _th ? 'ไม่มีข้อมูล' : 'No data';
  String get search      => _th ? 'ค้นหา...'  : 'Search...';

  // ── SETTINGS ────────────────────────────────────────────────
  String get settings           => _th ? 'ตั้งค่า'         : 'Settings';
  String get sectionAppearance  => _th ? 'รูปลักษณ์'        : 'Appearance';
  String get sectionLanguage    => _th ? 'ภาษา'             : 'Language';
  String get sectionNotif       => _th ? 'การแจ้งเตือน'     : 'Notifications';
  String get sectionData        => _th ? 'ข้อมูล'            : 'Data';
  String get sectionAbout       => _th ? 'เกี่ยวกับ'        : 'About';

  String get themeLabel         => _th ? 'ธีม'               : 'Theme';
  String get themeSystem        => _th ? 'ตามระบบ'           : 'System default';
  String get themeSystemDesc    => _th ? 'ตามธีมของอุปกรณ์'  : 'Follow device theme';
  String get themeLight         => _th ? 'โหมดสว่าง'         : 'Light mode';
  String get themeLightDesc     => _th ? 'สว่างและสะอาด'     : 'Bright & clean';
  String get themeDark          => _th ? 'โหมดมืด'           : 'Dark mode';
  String get themeDarkDesc      => _th ? 'สบายตา'            : 'Easy on the eyes';

  String get langThai           => _th ? 'ภาษาไทย'           : 'Thai';
  String get langThaiDesc       => _th ? 'แสดงข้อความเป็นภาษาไทย' : 'Display text in Thai';
  String get langEnglish        => _th ? 'ภาษาอังกฤษ'        : 'English';
  String get langEnglishDesc    => _th ? 'แสดงข้อความเป็นภาษาอังกฤษ' : 'Display text in English';

  String get deadlineReminders  => _th ? 'แจ้งเตือนกำหนดส่ง' : 'Deadline Reminders';
  String get deadlineRemindersDesc => _th ? 'รับการแจ้งเตือนก่อนถึงกำหนดส่งงาน' : 'Get notified before assignment deadlines';

  String get exportData         => _th ? 'ส่งออกข้อมูล'      : 'Export Data';
  String get exportDataDesc     => _th ? 'คัดลอกข้อมูลทั้งหมดเป็น JSON' : 'Copy all data as JSON to clipboard';
  String get exportedTitle      => _th ? 'ส่งออกสำเร็จ!'     : 'Data Exported!';
  String get exportedBody       => _th ? 'คัดลอกข้อมูลไปยังคลิปบอร์ดแล้ว สามารถวางในโปรแกรมแก้ไขข้อความได้'
                                        : 'Your data has been copied to clipboard as JSON.';
  String get gotIt              => _th ? 'รับทราบ'            : 'Got it';

  String get appVersion         => _th ? 'เวอร์ชัน 2.0.0'    : 'Version 2.0.0';
  String get builtWith          => _th ? 'พัฒนาด้วย Flutter'  : 'Built with Flutter';
  String get builtWithDesc      => _th ? 'Material Design 3 + Nunito' : 'Material Design 3 + Nunito Font';

  // ── DASHBOARD ───────────────────────────────────────────────
  String get greetingMorning    => _th ? '☀️ อรุณสวัสดิ์!'    : '☀️ Good morning!';
  String get greetingAfternoon  => _th ? '🌤️ สวัสดีตอนบ่าย!'  : '🌤️ Good afternoon!';
  String get greetingEvening    => _th ? '🌙 สวัสดีตอนเย็น!'  : '🌙 Good evening!';
  String overdueAlert(int n)    => _th ? '$n งานเกินกำหนด' : '$n overdue task${n > 1 ? 's' : ''}';

  String get statSubjects       => _th ? 'วิชาเรียน'          : 'Subjects';
  String get statPending        => _th ? 'รอดำเนินการ'        : 'Pending';
  String get statOverdue        => _th ? 'เกินกำหนด'          : 'Overdue';

  String get actionPomodoro     => _th ? 'โพโมโดโร'           : 'Pomodoro';
  String get actionAttendance   => _th ? 'การเข้าเรียน'       : 'Attendance';
  String get actionSubjects     => _th ? 'วิชาเรียน'          : 'Subjects';

  String get attendanceAlert    => _th ? 'เตือนการเข้าเรียน'  : 'Attendance Alert';
  String attendancePct(String pct) => _th ? 'เข้าเรียน: $pct% — ต่ำกว่า 75%'
                                           : 'Attendance: $pct% — below 75%';
  String get todayClasses       => _th ? 'ชั้นเรียนวันนี้'    : "Today's Classes";
  String pendingTasksHeader(int n) => _th ? 'งานที่รอดำเนินการ ($n)' : 'Pending Tasks ($n)';
  String moreTasks(int n)       => _th ? '+$n งานอีก' : '+$n more tasks';
  String get upcomingExams      => _th ? 'การสอบที่กำลังจะมาถึง' : 'Upcoming Exams';
  String get allTasksDone       => _th ? 'ทำงานครบทุกชิ้นแล้ว! 🎉' : 'All tasks done! 🎉';

  // ── SCHEDULE ────────────────────────────────────────────────
  String get schedule           => _th ? 'ตารางเรียน'         : 'Schedule';
  String get classes            => _th ? 'ชั้นเรียน'          : 'Classes';
  String get exams              => _th ? 'การสอบ'             : 'Exams';
  String get listView           => _th ? 'มุมมองรายการ'       : 'List View';
  String get calendarView       => _th ? 'มุมมองปฏิทิน'      : 'Calendar View';
  String get noClassesScheduled => _th ? 'ยังไม่มีชั้นเรียน'  : 'No classes scheduled';
  String get noExamsScheduled   => _th ? 'ยังไม่มีการสอบ'     : 'No exams scheduled';
  String get nothingOnThisDay   => _th ? 'ไม่มีกิจกรรมวันนี้' : 'Nothing on this day';
  String get nothingSubtitle    => _th ? 'ไม่มีชั้นเรียน การสอบ หรืองานส่ง' : 'No classes, exams, or deadlines';
  String get deleteSchedule     => _th ? 'ลบตาราง'            : 'Delete Schedule';
  String get deleteScheduleBody => _th ? 'ต้องการลบตารางนี้?' : 'Delete this schedule entry?';

  // ── TASKS / ASSIGNMENTS ─────────────────────────────────────
  String get tasks              => _th ? 'งานที่ได้รับ'       : 'Tasks';
  String get tabAll             => _th ? 'ทั้งหมด'            : 'All';
  String get tabPending         => _th ? 'รอดำเนินการ'        : 'Pending';
  String get tabDone            => _th ? 'เสร็จแล้ว'          : 'Done';
  String get noTasksYet         => _th ? 'ยังไม่มีงาน'        : 'No tasks yet';
  String get noTasksSubtitle    => _th ? 'แตะ + เพื่อเพิ่มงาน' : 'Tap + to add a task';
  String get overdueLabel       => _th ? 'เกินกำหนด'          : 'Overdue';
  String get deleteTask         => _th ? 'ลบงาน'              : 'Delete Task';
  String get deleteTaskBody     => _th ? 'ต้องการลบงานนี้?'   : 'Delete this task?';

  // ── GRADES ──────────────────────────────────────────────────
  String get grades             => _th ? 'เกรด'               : 'Grades';
  String get gpaTitle           => _th ? 'เกรดเฉลี่ยสะสม'    : 'Grade Point Average';
  String get gpaCalculator      => _th ? 'คำนวณเกรดเฉลี่ย'   : 'GPA Calculator';
  String get noGradesYet        => _th ? 'ยังไม่มีเกรด'       : 'No grades yet';
  String get score              => _th ? 'คะแนน'              : 'Score';
  String get gradeLabel         => _th ? 'เกรด'               : 'Grade';
  String get creditsLabel       => _th ? 'หน่วยกิต'           : 'Credits';
  String get entriesLabel       => _th ? 'รายการ'             : 'Entries';
  String get gpLabel            => _th ? 'จุด GP'             : 'GP';
  String get deleteGrade        => _th ? 'ลบเกรด'             : 'Delete Grade';

  // ── NOTES ───────────────────────────────────────────────────
  String get notes              => _th ? 'บันทึก'             : 'Notes';
  String get noNotesYet         => _th ? 'ยังไม่มีบันทึก'     : 'No notes yet';
  String get noNotesSubtitle    => _th ? 'แตะ + เพื่อเพิ่มบันทึก' : 'Tap + to add a note';
  String get deleteNote         => _th ? 'ลบบันทึก'           : 'Delete Note';

  // ── SUBJECTS ────────────────────────────────────────────────
  String get subjects           => _th ? 'วิชาเรียน'          : 'Subjects';
  String get noSubjectsYet      => _th ? 'ยังไม่มีวิชาเรียน'  : 'No subjects yet';
  String get noSubjectsSubtitle => _th ? 'แตะ + เพื่อเพิ่มวิชา' : 'Tap + to add your first subject';
  String get deleteSubject      => _th ? 'ลบวิชาเรียน'        : 'Delete Subject';

  // ── POMODORO ────────────────────────────────────────────────
  String get pomodoroTimer      => _th ? 'จับเวลาโพโมโดโร'   : 'Pomodoro Timer';
  String get focusTime          => _th ? '🎯 เวลาโฟกัส'       : '🎯 Focus Time';
  String get shortBreak         => _th ? '☕ พักสั้น'          : '☕ Short Break';
  String get longBreak          => _th ? '🌿 พักยาว'          : '🌿 Long Break';
  String get focusChip          => _th ? 'โฟกัส'              : 'Focus';
  String get shortBreakChip     => _th ? 'พักสั้น'            : 'Short Break';
  String get longBreakChip      => _th ? 'พักยาว'             : 'Long Break';
  String sessionCount(int n)    => _th ? '$n เซสชัน' : '$n session${n != 1 ? 's' : ''}';
  String get backToFocus        => _th ? '🎯 กลับมาโฟกัสกัน!' : '🎯 Back to focus!';
  String get takeBreak          => _th ? '☕ พักสักหน่อย!'    : '☕ Take a break!';

  // ── ATTENDANCE ──────────────────────────────────────────────
  String get attendance         => _th ? 'การเข้าเรียน'       : 'Attendance';
  String get present            => _th ? 'เข้าเรียน'          : 'Present';
  String get absent             => _th ? 'ขาดเรียน'           : 'Absent';
  String get late               => _th ? 'มาสาย'              : 'Late';

  @override
  bool updateShouldNotify(AppStrings old) => old.lang != lang;
}
