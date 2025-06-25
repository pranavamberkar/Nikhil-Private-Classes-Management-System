import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExamMarks extends StatefulWidget {
  const ExamMarks({super.key});
  @override
  _ExamMarksState createState() => _ExamMarksState();
}

class _ExamMarksState extends State<ExamMarks> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showAddTestDialog() {
    String? selectedClass;
    String? selectedSubject;
    DateTime? selectedDate;
    TextEditingController totalMarksController = TextEditingController();
    TextEditingController dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add Test"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Select Class"),
                      items: ["8", "9", "10"].map((String classValue) {
                        return DropdownMenuItem<String>(
                          value: classValue,
                          child: Text(classValue),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedClass = value;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Select Subject"),
                      items: [
                        "Marathi", "Hindi", "English", "Science 1", "Science 2",
                        "Maths 1", "Maths 2", "History & Civics", "Geography"
                      ].map((String subjectValue) {
                        return DropdownMenuItem<String>(
                          value: subjectValue,
                          child: Text(subjectValue),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedSubject = value;
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: "Select Date"),
                      readOnly: true,
                      controller: dateController,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                            dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                          });
                        }
                      },
                    ),
                    TextField(
                      controller: totalMarksController,
                      decoration: InputDecoration(labelText: "Total Marks"),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedClass == null ||
                        selectedSubject == null ||
                        selectedDate == null ||
                        totalMarksController.text.isEmpty ||
                        int.tryParse(totalMarksController.text) == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill all fields correctly'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    await _firestore.collection('tests').add({
                      'class': selectedClass,
                      'subject': selectedSubject,
                      'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
                      'totalMarks': int.parse(totalMarksController.text),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Test added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddMarksDialog(String className, String testId) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future: _firestore.collection('students').where('class', isEqualTo: className).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return AlertDialog(
                title: Text("Loading Students..."),
                content: CircularProgressIndicator(),
              );
            }

            List<DocumentSnapshot> students = snapshot.data!.docs;
            Map<String, TextEditingController> marksControllers = {
              for (var student in students) student.id: TextEditingController()
            };

            return AlertDialog(
              title: Text("Enter Marks"),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView(
                  children: students.map((student) {
                    return TextField(
                      controller: marksControllers[student.id],
                      decoration: InputDecoration(labelText: student['name']),
                      keyboardType: TextInputType.number,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    for (var student in students) {
                      String input = marksControllers[student.id]!.text;
                      if (input.isEmpty || int.tryParse(input) == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter valid marks for all students'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                    }
                    for (var student in students) {
                      await _firestore.collection('test_results').add({
                        'testId': testId,
                        'studentId': student.id,
                        'marks': int.parse(marksControllers[student.id]!.text),
                      });
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Marks published successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text("Publish"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMarksDialog(String testId) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future: _firestore.collection('test_results').where('testId', isEqualTo: testId).get(),
          builder: (context, resultsSnapshot) {
            if (!resultsSnapshot.hasData) {
              return AlertDialog(
                title: Text("Loading Marks..."),
                content: CircularProgressIndicator(),
              );
            }

            final results = resultsSnapshot.data!.docs;
            Map<String, TextEditingController> marksControllers = {};

            return FutureBuilder<QuerySnapshot>(
              future: _firestore.collection('students').get(),
              builder: (context, studentsSnapshot) {
                if (!studentsSnapshot.hasData) {
                  return AlertDialog(
                    title: Text("Loading Students..."),
                    content: CircularProgressIndicator(),
                  );
                }

                final students = {for (var doc in studentsSnapshot.data!.docs) doc.id: doc};

                for (var result in results) {
                  final marks = result['marks'].toString();
                  marksControllers[result.id] = TextEditingController(text: marks);
                }

                return AlertDialog(
                  title: Text("Edit Marks"),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: ListView(
                      children: results.map((result) {
                        final studentId = result['studentId'];
                        final studentName = students[studentId]?['name'] ?? 'Unknown';
                        return TextField(
                          controller: marksControllers[result.id],
                          decoration: InputDecoration(labelText: studentName),
                          keyboardType: TextInputType.number,
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        for (var result in results) {
                          String input = marksControllers[result.id]!.text;
                          if (input.isEmpty || int.tryParse(input) == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter valid marks for all students'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                        }

                        for (var result in results) {
                          await result.reference.update({
                            'marks': int.parse(marksControllers[result.id]!.text),
                          });
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Marks updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Text("Update"),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmDelete(DocumentReference reference) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this test?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await reference.delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Test deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Performance Tracking")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _showAddTestDialog,
              child: Text("Add Test"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('tests').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                  final tests = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: tests.length,
                    itemBuilder: (context, index) {
                      var test = tests[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                            "${test['subject']} - Class ${test['class']}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Date: ${test['date']} | Marks: ${test['totalMarks']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () => _showAddMarksDialog(test['class'], test.id),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _showEditMarksDialog(test.id),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _confirmDelete(test.reference),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
