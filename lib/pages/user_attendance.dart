import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserAttendancePage extends StatefulWidget {
  const UserAttendancePage({super.key});

  @override
  _UserAttendancePageState createState() => _UserAttendancePageState();
}

class _UserAttendancePageState extends State<UserAttendancePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _userId;
  String? _userClass;
  Map<DateTime, bool> _attendanceRecords = {};
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _userId = user.uid;
        });
        _fetchUserDataAndAttendance(_selectedMonth);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not logged in.')),
        );
      }
    });
  }

  Future<void> _fetchUserDataAndAttendance(DateTime selectedMonth) async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
      _attendanceRecords.clear();
    });

    try {
      DocumentSnapshot userDoc = await _firestore.collection('students').doc(_userId).get();
      if (!userDoc.exists) throw Exception("User class information not found.");
      _userClass = userDoc['class'];

      DateTime startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
      DateTime endDate = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

      List<Future<DocumentSnapshot>> attendanceFutures = [];

      for (DateTime date = startDate;
      date.isBefore(endDate.add(const Duration(days: 1)));
      date = date.add(const Duration(days: 1))) {
        String dateStr = date.toIso8601String().split('T').first;
        attendanceFutures.add(
          _firestore
              .collection('attendance')
              .doc(_userClass)
              .collection(dateStr)
              .doc(_userId)
              .get(),
        );
      }

      List<DocumentSnapshot> attendanceDocs = await Future.wait(attendanceFutures);
      Map<DateTime, bool> tempRecords = {};

      for (int i = 0; i < attendanceDocs.length; i++) {
        if (attendanceDocs[i].exists) {
          final data = attendanceDocs[i].data() as Map<String, dynamic>;
          tempRecords[startDate.add(Duration(days: i))] = data['present'] ?? false;
        }
      }

      setState(() {
        _attendanceRecords = tempRecords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching attendance: ${e.toString()}')),
      );
    }
  }

  void _changeMonth(DateTime newMonth) {
    setState(() {
      _selectedMonth = newMonth;
    });
    _fetchUserDataAndAttendance(newMonth);
  }

  @override
  Widget build(BuildContext context) {
    int presentCount = _attendanceRecords.values.where((value) => value).length;
    int absentCount = _attendanceRecords.values.where((value) => !value).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Attendance',style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchUserDataAndAttendance(_selectedMonth);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<DateTime>(
              value: _selectedMonth,
              onChanged: (DateTime? newMonth) {
                if (newMonth != null) {
                  _changeMonth(newMonth);
                }
              },
              items: List.generate(12, (index) {
                DateTime month = DateTime(DateTime.now().year, index + 1, 1);
                return DropdownMenuItem(
                  value: month,
                  child: Text(DateFormat.yMMMM().format(month)),
                );
              }),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendIndicator(Colors.green, "Present"),
                const SizedBox(width: 20),
                _legendIndicator(Colors.red, "Absent"),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Total Present: $presentCount   |   Total Absent: $absentCount",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendanceRecords.isEmpty
                ? const Center(
              child: Text(
                'No attendance records found.',
                style: TextStyle(fontSize: 16),
              ),
            )
                : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: _attendanceRecords.entries
                      .map(
                        (entry) => DataRow(
                      cells: [
                        DataCell(Text(
                            '${entry.key.year}-${entry.key.month.toString().padLeft(2, '0')}-${entry.key.day.toString().padLeft(2, '0')}')),
                        DataCell(Text(
                          entry.value ? 'Present' : 'Absent',
                          style: TextStyle(
                            color: entry.value ? Colors.green : Colors.red,
                          ),
                        )),
                      ],
                    ),
                  )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendIndicator(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
