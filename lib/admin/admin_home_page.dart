import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/admin/admin_analytics_dashboard.dart';
import 'student_management.dart';
import 'admin_attendance.dart';
import 'package:project/pages/login_page.dart';
import 'package:project/admin/admin_fees_check.dart';
import 'package:project/admin/admin_class_calendar.dart';
import 'package:project/admin/admin_chat.dart';
import 'package:project/admin/admin_notice.dart';
import 'package:project/admin/Exam_marks.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text("Logout"),
              ),
            ],
          ),
    );
  }

  Widget buildMenuButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
            'Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurpleAccent,
                child: Icon(
                    Icons.admin_panel_settings, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome, Admin!',
                style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildFixedSizeButton('Manage Students', Icons.group, () {
                      Navigator.push(context, MaterialPageRoute(builder: (
                          context) => StudentManagementPage()));
                    }),
                    const SizedBox(height: 15),
                    buildFixedSizeButton(
                        'Take Attendance', Icons.checklist, () {
                      Navigator.push(context, MaterialPageRoute(builder: (
                          context) => const AttendancePage()));
                    }),
                    const SizedBox(height: 15),
                    buildFixedSizeButton(
                        'Class Calendar', Icons.calendar_today, () {
                      Navigator.push(context, MaterialPageRoute(builder: (
                          context) => const ClassCalendarPage()));
                    }),
                    const SizedBox(height: 15),
                    buildFixedSizeButton(
                        'Notice Board', Icons.calendar_today, () {
                      Navigator.push(context, MaterialPageRoute(builder: (
                          context) => SendNoticePage()));
                    }),
                    const SizedBox(height: 15),
                    buildFixedSizeButton(
                        'Exam Marks', Icons.calendar_today, () {
                      Navigator.push(context, MaterialPageRoute(builder: (
                          context) => ExamMarks()));
                    }),
                    const SizedBox(height: 15),
                    buildFixedSizeButton(
                        'Analytical Dashboard', Icons.calendar_today, () {
                      Navigator.push(context, MaterialPageRoute(builder: (
                          context) => AnalyticsDashboardPage()));
                    }),
                    const SizedBox(height: 15),
                    buildFixedSizeButton(
                        'Fees Management', Icons.attach_money, () {
                      Navigator.push(context, MaterialPageRoute(builder: (
                          context) => const FeesManagementPage()));
                    }),
                    const SizedBox(height: 15),
                    buildFixedSizeButton('Admin Chat', Icons.chat, () {
                      Navigator.push(context, MaterialPageRoute(builder: (
                          context) => const AdminChatPage()));
                    }),
                    const SizedBox(height: 15),
                    buildFixedSizeButton('Log Out', Icons.exit_to_app, () =>
                        _showLogoutDialog(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFixedSizeButton(String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Text(title, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}