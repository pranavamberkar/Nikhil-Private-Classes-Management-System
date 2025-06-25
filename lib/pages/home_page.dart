import 'package:flutter/material.dart' hide CarouselController;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:project/pages/user_attendance.dart';
import 'package:project/pages/student_fees_update.dart';
import 'package:project/pages/login_page.dart';
import 'package:project/pages/class_calendar.dart';
import 'package:project/pages/chat_page.dart';
import 'package:project/pages/perfomance_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? studentName;
  String? studentClass;
  String? latestNotice;
  bool isLoading = true;

  final List<String> imgList = [
    'lib/images/class1.jpg',
    'lib/images/class2.jpg',
    'lib/images/class3.jpg',
    'lib/images/class4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(fetchStudentData);
  }

  Future<void> fetchStudentData() async {
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          studentName = 'No User Logged In';
          isLoading = false;
        });
        return;
      }

      final uid = user.uid;
      final doc = await FirebaseFirestore.instance.collection('students').doc(uid).get();

      if (doc.exists) {
        studentName = doc.data()?['name'] ?? 'Student';
        studentClass = doc.data()?['class'] ?? '';

        await fetchLatestNotice();
      } else {
        studentName = 'Student Not Found';
      }
    } catch (e) {
      studentName = 'Error fetching data';
      print("Error fetching student data: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchLatestNotice() async {
    try {
      if (studentClass == null || studentClass!.isEmpty) return;

      print("Fetching notices for class: $studentClass");

      final querySnapshot = await FirebaseFirestore.instance
          .collection('notices')
          .where('class', isEqualTo: studentClass)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final noticeData = querySnapshot.docs.first.data();
        latestNotice = noticeData['notice'];

        final Timestamp? timestamp = noticeData['timestamp'];
        if (timestamp != null) {
          DateTime noticeTime = timestamp.toDate();
          String formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(noticeTime);
          latestNotice = "$latestNotice\n\n $formattedTime";
        }

        print("Notice found: $latestNotice");
      } else {
        latestNotice = 'No notices available';
        print("No notices found for class: $studentClass");
      }
    } catch (e) {
      latestNotice = 'Error fetching notice';
      print("Error fetching notice: $e");
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget buildMenuButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Welcome, ${studentName ?? 'Student'}!', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchStudentData,
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.deepPurpleAccent)
              : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Carousel slider with class images
                CarouselSlider(
                  options: CarouselOptions(
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    autoPlayInterval: const Duration(seconds: 3),
                  ),
                  items: imgList.map((item) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        item,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),
                if (latestNotice != null)
                  Card(
                    color: Colors.amberAccent,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Notice: $latestNotice',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                buildMenuButton('View Attendance', Icons.list_alt, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UserAttendancePage()));
                }),
                const SizedBox(height: 15),
                buildMenuButton('Class Calendar', Icons.calendar_today, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => StudentTimetablePage()));
                }),
                const SizedBox(height: 15),
                buildMenuButton('Perfomance Tracking', Icons.attach_money, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentPerformancePage()));
                }),
                const SizedBox(height: 15),
                buildMenuButton('Fees Records', Icons.attach_money, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FeesManagementPage()));
                }),
                const SizedBox(height: 15),
                buildMenuButton('Chat', Icons.chat, () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentChatPage(user.uid)));
                  } else {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text("User not logged in")));
                  }
                }),
                const SizedBox(height: 15),
                buildMenuButton('Log Out', Icons.exit_to_app, () => _showLogoutDialog(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
