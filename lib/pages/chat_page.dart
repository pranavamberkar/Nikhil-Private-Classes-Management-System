import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentChatPage extends StatefulWidget {
  final String studentId;
  const StudentChatPage(this.studentId, {super.key});

  @override
  _StudentChatPageState createState() => _StudentChatPageState();
}

class _StudentChatPageState extends State<StudentChatPage> {
  TextEditingController messageController = TextEditingController();
  FocusNode messageFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: Text("Chat with Admin",style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurpleAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.studentId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No messages yet"));
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isStudent = message['sender'] == 'Student';
                    String time = formatTimestamp(message['timestamp']);

                    return Align(
                      alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Card(
                          color: isStudent ? Colors.blue[200] : Colors.grey[300],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['text'],
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  time,
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    focusNode: messageFocusNode,
                    decoration: InputDecoration(
                      labelText: "Enter message",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () async {
                    if (messageController.text.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.studentId)
                          .collection('messages')
                          .add({
                        'text': messageController.text,
                        'sender': 'Student',
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      messageController.clear();
                      messageFocusNode.unfocus();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}";
    }
    return "Sending...";
  }
}
