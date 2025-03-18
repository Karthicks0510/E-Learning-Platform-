// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;

  ChatScreen({required this.currentUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> _searchResults = [];
  List<DocumentSnapshot> _recentChats = [];

  @override
  void initState() {
    super.initState();
    _loadRecentChats();
  }

  Future<void> _loadRecentChats() async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${widget.currentUserId}_')
          .where(FieldPath.documentId, isLessThan: '${widget.currentUserId}_\uf7ff')
          .get();

      final querySnapshot2 = await _firestore
          .collection('chats')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '_${widget.currentUserId}')
          .where(FieldPath.documentId, isLessThan: '_\uf7ff${widget.currentUserId}')
          .get();

      List<DocumentSnapshot> allChats = [...querySnapshot.docs, ...querySnapshot2.docs];

      setState(() {
        _recentChats = allChats;
      });
    } catch (e) {
      print('Error loading recent chats: $e');
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isNotEmpty) {
      try {
        final querySnapshot = await _firestore
            .collection('users')
            .where('username', isGreaterThanOrEqualTo: query)
            .where('username', isLessThan: query + '\uf7ff')
            .get();

        setState(() {
          _searchResults = querySnapshot.docs;
        });
      } catch (e) {
        print('Error searching users: $e');
      }
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _startChat(String otherUserId, String otherUserName) {
    String chatId = widget.currentUserId.compareTo(otherUserId) < 0
        ? '${widget.currentUserId}_$otherUserId'
        : '$otherUserId\_${widget.currentUserId}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoom(
          chatId: chatId,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.isNotEmpty
                    ? _searchResults.length
                    : _recentChats.length,
                itemBuilder: (context, index) {
                  if (_searchResults.isNotEmpty) {
                    final user = _searchResults[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user['username'][0].toUpperCase()),
                      ),
                      title: Text(user['username']),
                      onTap: () => _startChat(_searchResults[index].id, user['username']),
                    );
                  } else {
                    final chatId = _recentChats[index].id;
                    List<String> parts = chatId.split('_');
                    String otherUserId = parts[0] == widget.currentUserId ? parts[1] : parts[0];

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(otherUserId).get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return ListTile(title: Text("Loading..."));
                        }
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final userData = snapshot.data!.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(userData['username'][0].toUpperCase()),
                            ),
                            title: Text(userData['username']),
                            onTap: () => _startChat(otherUserId, userData['username']),
                          );
                        } else {
                          return ListTile(title: Text("User not found"));
                        }
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatRoom extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String currentUserId;

  ChatRoom({required this.chatId, required this.otherUserId, required this.otherUserName, required this.currentUserId});

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _firestore.collection('chats').doc(widget.chatId).collection('messages').add({
        'text': _messageController.text,
        'senderId': widget.currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('chats').doc(widget.chatId).collection('messages').orderBy('timestamp').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final message = snapshot.data!.docs[index];
                      final data = message.data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == widget.currentUserId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[200] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(data['text']),
                        ),
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
                    decoration: InputDecoration(hintText: 'Type a message...'),
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