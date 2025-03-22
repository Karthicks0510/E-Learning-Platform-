import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final String chatPartnerId;

  const ChatRoomScreen({Key? key, required this.chatRoomId, required this.chatPartnerId}) : super(key: key);

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _firestore.collection('chatRooms').doc(widget.chatRoomId).collection('messages').add({
        'text': _messageController.text,
        'senderId': _auth.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
      _scrollToBottom();
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('yMMMd').format(timestamp.toDate());
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('h:mm a').format(timestamp.toDate());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxMessageWidth = screenWidth * 0.7;
    final maxInputWidth = screenWidth * 0.8;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Text(
          'Chat',
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white), // Set back arrow color to white
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chatRooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(fontFamily: 'Open Sans', color: Colors.red)));
                }

                final messages = snapshot.data?.docs ?? [];
                Map<String, List<QueryDocumentSnapshot>> groupedMessages = {};

                for (var msg in messages) {
                  final msgData = msg.data() as Map<String, dynamic>;
                  final msgDate = formatDate(msgData['timestamp']);
                  if (!groupedMessages.containsKey(msgDate)) {
                    groupedMessages[msgDate] = [];
                  }
                  groupedMessages[msgDate]!.add(msg);
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: groupedMessages.length,
                  itemBuilder: (context, index) {
                    String date = groupedMessages.keys.elementAt(index);
                    var dayMessages = groupedMessages[date]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(date, style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w500, fontFamily: 'Open Sans')),
                          ),
                        ),
                        ...dayMessages.map((messageDoc) {
                          final message = messageDoc.data() as Map<String, dynamic>;
                          final isMe = message['senderId'] == _auth.currentUser!.uid;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxMessageWidth),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.purple.shade300 : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(message['text'] ?? '', style: TextStyle(color: Colors.black, fontFamily: 'Open Sans')),
                                    const SizedBox(height: 4),
                                    Text(formatTime(message['timestamp']), style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontFamily: 'Open Sans')),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxInputWidth),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                          hintStyle: TextStyle(fontFamily: 'Open Sans'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: TextStyle(fontFamily: 'Open Sans'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.purple),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}