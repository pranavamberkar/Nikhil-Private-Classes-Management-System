import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  _AttendancePage createState() => _AttendancePage();
}

class _AttendancePage extends State<AttendancePage> {
  String _selectedClass = '8';
  final List<String> _classes = ['8', '9', '10'];
  bool _isSubmitting = false;

  final TextEditingController _dateController = TextEditingController();
  final CollectionReference _studentsCollection =
  FirebaseFirestore.instance.collection('students');
  final CollectionReference _attendanceCollection =
  FirebaseFirestore.instance.collection('attendance');

  List<Map<String, dynamic>> _students = [];

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _students.clear();
    });

    try {
      QuerySnapshot querySnapshot = await _studentsCollection
          .where('class', isEqualTo: _selectedClass)
          .get();

      setState(() {
        _students = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'userId': doc.id,
            'name': data['name'],
            'rollNo': data['rollNo'],
            'present': false,
          };
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching students: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitAttendance() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students found for this class'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String date = _dateController.text.trim();
    if (date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the date')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var student in _students) {
        batch.set(
          _attendanceCollection
              .doc(_selectedClass)
              .collection(date)
              .doc(student['userId']),
          {
            'userId': student['userId'],
            'name': student['name'],
            'rollNo': student['rollNo'],
            'present': student['present'],
          },
        );
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting attendance: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _generateAttendancePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Attendance Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Class: $_selectedClass',
                  style: pw.TextStyle(fontSize: 16)),
              pw.Text('Date: ${_dateController.text}',
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Roll No', 'Name', 'Status'],
                data: _students.map((student) {
                  return [
                    student['rollNo'].toString(),
                    student['name'].toString(),
                    student['present'] ? 'Present' : 'Absent',
                  ];
                }).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Take Attendance', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchStudents,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _generateAttendancePDF,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedClass,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedClass = newValue);
                  _fetchStudents();
                }
              },
              items: _classes.map((className) {
                return DropdownMenuItem<String>(
                  value: className,
                  child: Text(
                    'Class $className',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Attendance Date (YYYY-MM-DD)',
              ),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                _dateController.text =
                '${pickedDate?.year}-${pickedDate?.month.toString().padLeft(2, '0')}-${pickedDate?.day.toString().padLeft(2, '0')}';
                            },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _students.isEmpty
                  ? const Center(child: Text('No students to display'))
                  : ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_students[index]['name']),
                    subtitle:
                    Text('Roll No: ${_students[index]['rollNo']}'),
                    trailing: Switch(
                      value: _students[index]['present'],
                      onChanged: (bool value) {
                        setState(() {
                          _students[index]['present'] = value;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAttendance,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Attendance'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
