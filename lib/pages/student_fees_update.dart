import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeesManagementPage extends StatefulWidget {
  const FeesManagementPage({super.key});

  @override
  State<FeesManagementPage> createState() => _FeesManagementPageState();
}

class _FeesManagementPageState extends State<FeesManagementPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _fetchStudentId();
  }

  Future<void> _fetchStudentId() async {
    String? userEmail = _auth.currentUser?.email;

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('students')
          .where('email', isEqualTo: userEmail)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _studentId = querySnapshot.docs.first.id;
        });
      }
    } catch (e) {
      print("Error fetching student ID: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_studentId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fees Management',style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('fees').doc(_studentId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No fee records found'));
          }

          Map<String, dynamic> feeData = snapshot.data!.data() as Map<String, dynamic>;
          int totalFees = feeData['totalFees'] ?? 0;
          List payments = feeData['payments'] ?? [];
          int paidFees = payments.fold(0, (sum, payment) => sum + (payment['amount'] as int));
          int pendingFees = totalFees - paidFees;
          String lastPayment = payments.isNotEmpty
              ? '₹${payments.last['amount']} on ${payments.last['date']} (${payments.last['mode']})'
              : 'No payment records';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Fees: ₹$totalFees',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Pending Fees: ₹$pendingFees',
                    style: const TextStyle(fontSize: 18, color: Colors.red)),
                Text('Last Payment: $lastPayment', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                const Text('Payment History:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: payments.isEmpty
                      ? const Center(child: Text('No payment history'))
                      : ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      var payment = payments[index];
                      return ListTile(
                        title: Text('Amount: ₹${payment['amount']}'),
                        subtitle: Text('Date: ${payment['date']} | Mode: ${payment['mode']}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
