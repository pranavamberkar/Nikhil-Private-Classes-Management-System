import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: FeesManagementPage()));
}

class FeesManagementPage extends StatefulWidget {
  const FeesManagementPage({super.key});

  @override
  State<FeesManagementPage> createState() => _FeesManagementPageState();
}

class _FeesManagementPageState extends State<FeesManagementPage> {
  final _studentsCollection = FirebaseFirestore.instance.collection('students');
  final _classes = ['8', '9', '10'];

  Widget _buildStudentList(String selectedClass) {
    return StreamBuilder(
      stream: _studentsCollection.where('class', isEqualTo: selectedClass).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No students found'));

        return ListView(
          padding: const EdgeInsets.all(8),
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data();
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(data['name'][0], style: const TextStyle(color: Colors.white)),
                ),
                title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Class: ${data['class']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentDetailsPage(studentId: doc.id, studentData: data)),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _classes.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fees Management', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurpleAccent,
          iconTheme: IconThemeData(color: Colors.white),
          bottom: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white,
              tabs: _classes.map((c) => Tab(text: 'Class $c')).toList()
          ),
        ),
        body: TabBarView(children: _classes.map((c) => _buildStudentList(c)).toList()),
      ),
    );
  }
}

class StudentDetailsPage extends StatefulWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const StudentDetailsPage({super.key, required this.studentId, required this.studentData});

  @override
  _StudentDetailsPageState createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  final _feesCollection = FirebaseFirestore.instance.collection('fees');
  final _totalFeesController = TextEditingController();
  final _paymentAmountController = TextEditingController();
  final _paymentDateController = TextEditingController();
  int _pendingFees = 0, _paidFees = 0;
  List<Map<String, dynamic>> _payments = [];
  bool _isEditing = false;

  // Default payment mode
  String _paymentMode = 'Cash';

  @override
  void initState() {
    super.initState();
    _fetchFees();
  }

  Future<void> _fetchFees() async {
    try {
      var doc = await _feesCollection.doc(widget.studentId).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _totalFeesController.text = data['totalFees'].toString();
          _payments = List<Map<String, dynamic>>.from(data['payments'] ?? []);
          _paidFees = _payments.fold(0, (sum, p) => sum + (p['amount'] as int));
          _pendingFees = (int.tryParse(_totalFeesController.text) ?? 0) - _paidFees;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching fees: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateFees() async {
    await _feesCollection.doc(widget.studentId).set({
      'totalFees': int.tryParse(_totalFeesController.text) ?? 0,
      'payments': _payments,
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fees updated successfully!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _addPayment() async {
    int paymentAmount = int.tryParse(_paymentAmountController.text) ?? 0;
    if (paymentAmount > 0) {
      setState(() {
        _payments.add({
          'date': _paymentDateController.text.isEmpty
              ? DateTime.now().toIso8601String()
              : _paymentDateController.text,
          'amount': paymentAmount,
          'mode': _paymentMode, // Now storing selected payment mode
        });
        _paidFees = _payments.fold(0, (sum, p) => sum + (p['amount'] as int));
        _pendingFees = (int.tryParse(_totalFeesController.text) ?? 0) - _paidFees;
      });
      await _updateFees();
      _paymentAmountController.clear();
      _paymentDateController.clear();
    }
  }

  Future<void> _selectDate() async {
    DateTime? selectedDate = await showDatePicker(
        context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
    setState(() => _paymentDateController.text = "${selectedDate?.toLocal()}".split(' ')[0]);
    }

  void _toggleEditing() => setState(() => _isEditing = !_isEditing);

  void _saveChanges() {
    setState(() => _pendingFees = (int.tryParse(_totalFeesController.text) ?? 0) - _paidFees);
    _updateFees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentData['name'], style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${widget.studentData['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Roll No: ${widget.studentData['rollNo']}'),
              Text('Class: ${widget.studentData['class']}'),
              const Divider(height: 24),
              TextField(
                controller: _totalFeesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Fees'),
                enabled: _isEditing,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(onPressed: _toggleEditing, child: Text(_isEditing ? 'Cancel' : 'Edit')),
                  const SizedBox(width: 10),
                  if (_isEditing) ElevatedButton(onPressed: _saveChanges, child: const Text('Save')),
                ],
              ),
              const SizedBox(height: 10),
              Text('Pending Fees: ₹$_pendingFees', style: const TextStyle(color: Colors.red)),
              Text('Paid Fees: ₹$_paidFees', style: const TextStyle(color: Colors.green)),
              const Divider(height: 24),
              TextField(
                controller: _paymentAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Payment Amount'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _paymentDateController,
                decoration: const InputDecoration(labelText: 'Payment Date'),
                onTap: _selectDate,
                readOnly: true,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Text('Payment Mode: ', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _paymentMode,
                    items: ['Cash', 'Online'].map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(mode),
                      );
                    }).toList(),
                    onChanged: (newMode) {
                      setState(() {
                        _paymentMode = newMode!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ElevatedButton(onPressed: _addPayment, child: const Text('Add Payment')),
              SizedBox(
                height: 200,
                child: ListView(
                  children: _payments.map((p) => ListTile(
                    title: Text('₹${p['amount']}'),
                    subtitle: Text('Date: ${p['date']} | Mode: ${p['mode']}'),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
