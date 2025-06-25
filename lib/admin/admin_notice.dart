import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class SendNoticePage extends StatefulWidget {
  const SendNoticePage({super.key});

  @override
  State<SendNoticePage> createState() => _SendNoticePageState();
}

class _SendNoticePageState extends State<SendNoticePage> {
  final TextEditingController _noticeController = TextEditingController();
  String? selectedClass;

  Future<void> sendNotice() async {
    if (_noticeController.text.isEmpty || selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please enter notice and select a class"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    await FirebaseFirestore.instance.collection('notices').add({
      'notice': _noticeController.text,
      'class': selectedClass,
      'timestamp': FieldValue.serverTimestamp(), // Added timestamp field
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Notice sent successfully!"),
      backgroundColor: Colors.green,
    ));

    _noticeController.clear();
  }

  Future<void> _confirmDeleteNotice(String docId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Notice"),
        content: const Text("Are you sure you want to delete this notice?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('notices').doc(docId).delete();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Notice deleted successfully!"),
                backgroundColor: Colors.red,
              ));
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Notice", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _noticeController,
              decoration: const InputDecoration(
                labelText: "Enter Notice",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedClass,
              onChanged: (value) => setState(() => selectedClass = value),
              items: ['10', '9', '8']
                  .map((className) => DropdownMenuItem(
                value: className,
                child: Text("Class $className"),
              ))
                  .toList(),
              decoration: const InputDecoration(
                labelText: "Select Class",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: sendNotice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50), // Increased width
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Smooth edges
              ),
              child: const Text(
                "Send Notice",
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notices')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final notices = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: notices.length,
                    itemBuilder: (context, index) {
                      final doc = notices[index];
                      final noticeText = doc['notice'];
                      final className = doc['class'];
                      final Timestamp? timestamp = doc['timestamp']; // Fetch timestamp

                      String formattedTime = "No timestamp";
                      if (timestamp != null) {
                        DateTime dateTime = timestamp.toDate();
                        formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(dateTime); // Format date & time
                      }

                      return Card(
                        color: Colors.amberAccent,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(noticeText, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Class: $className"),
                              Text("Posted on: $formattedTime"), // Added timestamp display
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteNotice(doc.id),
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
