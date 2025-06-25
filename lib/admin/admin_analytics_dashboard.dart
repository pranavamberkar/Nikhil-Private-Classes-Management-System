import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_Performance_Page.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});
  @override
  _AnalyticsDashboardPageState createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  String? selectedClass;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Analytics Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedClass,
              hint: Text("Select Class"),
              items: ["8", "9", "10"].map((classValue) {
                return DropdownMenuItem(
                  value: classValue,
                  child: Text("Class $classValue"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedClass = value;
                });
              },
            ),
            SizedBox(height: 20),
            selectedClass != null
                ? Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .where('class', isEqualTo: selectedClass)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data!.docs;

                  if (students.isEmpty) {
                    return Center(child: Text("No students found"));
                  }

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Card(
                        child: ListTile(
                          title: Text(student['name']),
                          subtitle: Text("Roll No: ${student['rollNo']}"),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentPerformancePage(
                                  studentId: student.id,
                                  studentName: student['name'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            )
                : Center(child: Text("Please select a class")),
          ],
        ),
      ),
    );
  }
}
