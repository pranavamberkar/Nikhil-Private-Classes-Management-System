import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassCalendarPage extends StatefulWidget {
  const ClassCalendarPage({super.key});

  @override
  _ClassCalendarPageState createState() => _ClassCalendarPageState();
}

class _ClassCalendarPageState extends State<ClassCalendarPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedClass = '8';
  String _selectedDay = 'Monday';
  String _subject = '';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final List<String> classes = ['8', '9', '10'];
  final List<String> days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  void _selectTime(BuildContext context, bool isStartTime) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveTimetable() async {
    if (_formKey.currentState!.validate() && _startTime != null && _endTime != null) {
      _formKey.currentState!.save();

      await FirebaseFirestore.instance
          .collection('timetables')
          .doc(_selectedClass)
          .collection(_selectedDay)
          .add({
        'subject': _subject,
        'startTime': _startTime!.format(context),
        'endTime': _endTime!.format(context),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Timetable entry added successfully!'),
        backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    }
  }

  void _deleteTimetable(String docId) async {
    await FirebaseFirestore.instance
        .collection('timetables')
        .doc(_selectedClass)
        .collection(_selectedDay)
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Timetable entry deleted!'),
      backgroundColor: Colors.red,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
          title: Text('Manage Class Timetable', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurpleAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField(
                      value: _selectedClass,
                      decoration: InputDecoration(labelText: 'Select Class'),
                      items: classes.map((cls) {
                        return DropdownMenuItem(value: cls, child: Text('Class $cls'));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClass = value!;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField(
                      value: _selectedDay,
                      decoration: InputDecoration(labelText: 'Select Day'),
                      items: days.map((day) {
                        return DropdownMenuItem(value: day, child: Text(day));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value!;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Enter Subject'),
                      validator: (value) => value!.isEmpty ? 'Enter a subject' : null,
                      onSaved: (value) => _subject = value!,
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(_startTime == null ? 'Select Start Time' : _startTime!.format(context)),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => _selectTime(context, true),
                          child: Text('Pick Start Time'),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(_endTime == null ? 'Select End Time' : _endTime!.format(context)),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => _selectTime(context, false),
                          child: Text('Pick End Time'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveTimetable,
                      child: Text('Save Timetable'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Saved Timetable Entries',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('timetables')
                    .doc(_selectedClass)
                    .collection(_selectedDay)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No timetable available for selected class and day.'));
                  }

                  var docs = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text('${data['subject']}'),
                          subtitle: Text('${data['startTime']} - ${data['endTime']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTimetable(docs[index].id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
