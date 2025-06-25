import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatPage extends StatefulWidget {
  const AdminChatPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminChatPage> {
  String? selectedStudentId;
  String? selectedStudentName;
  TextEditingController messageController = TextEditingController();
  FocusNode messageFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedStudentId == null ? "Admin Panel" : "Chat with $selectedStudentName",style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (selectedStudentId != null) {
              setState(() {
                selectedStudentId = null;
                selectedStudentName = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: selectedStudentId == null ? _buildStudentList() : _buildChatScreen(),
    );
  }

  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error loading students"));
        if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        var students = snapshot.data!.docs;

        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            var student = students[index];
            return Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    student['name'][0].toUpperCase(),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  student['name'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Class: ${student['class']}",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.blueAccent),
                onTap: () {
                  setState(() {
                    selectedStudentId = student.id;
                    selectedStudentName = student['name'];
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatScreen() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(selectedStudentId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error loading messages"));
              if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
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
                          padding: EdgeInsets.all(12),
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
                                style: TextStyle(fontSize: 10, color: Colors.black54),
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
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              focusNode: messageFocusNode,
              decoration: InputDecoration(
                labelText: "Enter message",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: () {
                if (messageController.text.isNotEmpty) {
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(selectedStudentId)
                      .collection('messages')
                      .add({
                    'text': messageController.text,
                    'sender': 'Admin',
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  messageController.clear();
                  messageFocusNode.unfocus();
                }
              },
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
