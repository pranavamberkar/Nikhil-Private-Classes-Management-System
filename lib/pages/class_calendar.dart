import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentTimetablePage extends StatefulWidget {
  const StudentTimetablePage({super.key});

  @override
  _StudentTimetablePageState createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<StudentTimetablePage> {
  String? studentClass;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _fetchStudentClass();
  }

  Future<void> _fetchStudentClass() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();
      if (studentSnapshot.exists) {
        setState(() {
          studentClass = studentSnapshot['class'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Timetable',style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: studentClass == null
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: days.length,
        itemBuilder: (context, index) {
          String day = days[index];
          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('timetables')
                .doc(studentClass)
                .collection(day)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              var documents = snapshot.data!.docs;
              if (documents.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      title: Text(
                        '$day: No classes scheduled',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                        ),
                        padding: EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      ...documents.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(
                            data['subject'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${data['startTime']} - ${data['endTime']}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          leading: Icon(Icons.schedule, color: Colors.blueAccent),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
