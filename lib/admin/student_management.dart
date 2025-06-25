import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentManagementPage extends StatefulWidget {
  @override
  _StudentManagementPageState createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _enrollmentDateController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addStudent() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      try {
        var userDoc = await _firestore.collection('users').where('email', isEqualTo: email).get();
        if (userDoc.docs.isNotEmpty) {
          String uid = userDoc.docs.first.id;
          await _firestore.collection('students').doc(uid).set({
            'name': _nameController.text,
            'rollNo': _rollNoController.text,
            'class': _classController.text,
            'phone': _phoneController.text,
            'enrollment_date': _enrollmentDateController.text,
            'email': email,
            'uid': uid,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Student added successfully'), backgroundColor: Colors.green),
          );
          _clearFields();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not found'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteStudent(String uid) async {
    await _firestore.collection('students').doc(uid).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Student deleted successfully'), backgroundColor: Colors.red),
    );
  }

  void _clearFields() {
    _nameController.clear();
    _rollNoController.clear();
    _classController.clear();
    _phoneController.clear();
    _emailController.clear();
    _enrollmentDateController.clear();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _enrollmentDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Student Management', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurpleAccent,
          iconTheme: IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(text: 'Add'),
              Tab(text: 'Delete'),
              Tab(text: 'Show'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAddStudentTab(),
            _buildStudentList(deleteMode: true),
            _buildStudentList(deleteMode: false),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStudentTab() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(controller: _nameController, decoration: InputDecoration(labelText: 'Name'), validator: (value) => value!.isEmpty ? 'Enter Name' : null),
            TextFormField(controller: _rollNoController, decoration: InputDecoration(labelText: 'Roll No'), validator: (value) => value!.isEmpty ? 'Enter Roll No' : null),
            TextFormField(controller: _classController, decoration: InputDecoration(labelText: 'Class'), validator: (value) => value!.isEmpty ? 'Enter Class' : null),
            TextFormField(controller: _phoneController, decoration: InputDecoration(labelText: 'Phone Number'), validator: (value) => value!.isEmpty ? 'Enter Phone Number' : null),
            TextFormField(controller: _emailController, decoration: InputDecoration(labelText: 'Email ID'), validator: (value) => value!.isEmpty ? 'Enter Email ID' : null),
            TextFormField(
              controller: _enrollmentDateController,
              decoration: InputDecoration(labelText: 'Enrollment Date'),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _addStudent, child: Text('Add Student')),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList({required bool deleteMode}) {
    return StreamBuilder(
      stream: _firestore.collection('students').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${doc['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Roll No: ${doc['rollNo']}', style: TextStyle(fontSize: 16)),
                    Text('Class: ${doc['class']}', style: TextStyle(fontSize: 16)),
                    Text('Phone: ${doc['phone']}', style: TextStyle(fontSize: 16)),
                    Text('Email: ${doc['email']}', style: TextStyle(fontSize: 16)),
                    Text('Enrollment Date: ${doc['enrollment_date']}', style: TextStyle(fontSize: 16)),
                    if (deleteMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteStudent(doc.id),
                          icon: Icon(Icons.delete, color: Colors.white),
                          label: Text('Delete', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
