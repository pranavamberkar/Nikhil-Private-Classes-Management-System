import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StudentPerformancePage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentPerformancePage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  _StudentPerformancePageState createState() => _StudentPerformancePageState();
}

class _StudentPerformancePageState extends State<StudentPerformancePage> {
  bool _loading = true;
  Map<String, List<Map<String, dynamic>>> subjectMarks = {};
  double averageMarks = 0.0;
  List<BarChartGroupData> barGroups = [];

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    final firestore = FirebaseFirestore.instance;
    try {
      final studentSnapshot = await firestore.collection('students').doc(widget.studentId).get();
      if (!studentSnapshot.exists) {
        throw Exception('Student record not found');
      }

      final resultSnapshot = await firestore
          .collection('test_results')
          .where('studentId', isEqualTo: widget.studentId)
          .get();

      final testsSnapshot = await firestore.collection('tests').get();
      final tests = {for (var doc in testsSnapshot.docs) doc.id: doc};

      num totalMarks = 0;
      int totalEntries = 0;
      subjectMarks.clear();

      for (var result in resultSnapshot.docs) {
        final testId = result['testId'];
        final marks = result['marks'];
        final testDoc = tests[testId];
        if (testDoc == null) continue;

        final subject = testDoc['subject'] ?? 'Unknown';
        final date = testDoc['date'] ?? '-';
        final total = testDoc['totalMarks'] ?? 0;

        subjectMarks.putIfAbsent(subject, () => []).add({
          'marks': marks,
          'total': total,
          'date': date,
        });

        totalMarks += marks;
        totalEntries++;
      }

      averageMarks = totalEntries > 0 ? totalMarks / totalEntries : 0;

      int index = 0;
      barGroups.clear();
      subjectMarks.forEach((subject, tests) {
        double avg = tests.map((t) => t['marks'] as num).reduce((a, b) => a + b) / tests.length;
        barGroups.add(
          BarChartGroupData(x: index++, barRods: [
            BarChartRodData(toY: avg.toDouble(), color: Colors.blue, width: 18)
          ]),
        );
      });

      setState(() {
        _loading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                String subject = subjectMarks.keys.elementAt(value.toInt());
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    subject.length > 6 ? "${subject.substring(0, 6)}..." : subject,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Future<void> _downloadPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Text("Performance Report for ${widget.studentName}",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text("Average Marks: ${averageMarks.toStringAsFixed(2)}"),
          pw.SizedBox(height: 20),
          ...subjectMarks.entries.map((entry) {
            String subject = entry.key;
            List<Map<String, dynamic>> tests = entry.value;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(subject,
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ...tests.map((test) {
                  double percentage = (test['marks'] / test['total']) * 100;
                  return pw.Bullet(
                    text:
                    "${test['date']} - ${test['marks']}/${test['total']}  (${percentage.toStringAsFixed(2)}%)",
                  );
                }),
                pw.SizedBox(height: 10),
              ],
            );
          }),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: Text("Performance - ${widget.studentName}"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _downloadPDF,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Average Marks: ${averageMarks.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("Subject-wise Performance:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 250, child: _buildBarChart()),
            const SizedBox(height: 30),
            const Text("Full Report Card:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ...subjectMarks.entries.map((entry) {
              String subject = entry.key;
              List<Map<String, dynamic>> tests = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ...tests.map((test) {
                        double percentage = (test['marks'] / test['total']) * 100;
                        return ListTile(
                          title: Text("Test Date: ${test['date']}"),
                          subtitle: Text(
                              "Marks: ${test['marks']}/${test['total']} (${percentage.toStringAsFixed(2)}%)"),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
