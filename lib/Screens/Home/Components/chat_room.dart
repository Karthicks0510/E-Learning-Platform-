// chat_room.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatRoom extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String currentUserId;

  ChatRoom({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.currentUserId,
  });

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      try {
        await _firestore
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .add({
          'text': _messageController.text,
          'senderId': widget.currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
        _messageController.clear();
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final message = snapshot.data!.docs[index];
                      final data = message.data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == widget.currentUserId;
                      final timestamp = data['timestamp'] as Timestamp;
                      final dateTime = timestamp.toDate();
                      final time = DateFormat('hh:mm a').format(dateTime);
                      final date = DateFormat('yyyy-MM-dd').format(dateTime);
                      final day = DateFormat('EEEE').format(dateTime);

                      return Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (index == 0 ||
                              DateFormat('yyyy-MM-dd').format((snapshot
                                  .data!.docs[index - 1].data()
                              as Map<String, dynamic>)['timestamp']
                                  .toDate()) !=
                                  date)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('$day, $date',
                                    style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          Align(
                            alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.blue[200]
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['text']),
                                  Text(time, style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages'));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration:
                    InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}