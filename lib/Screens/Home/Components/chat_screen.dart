// chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room.dart';
import '../home_screen.dart';

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
  List<DocumentSnapshot> _chatRooms = [];

  @override
  void initState() {
    super.initState();
    _fetchChatRooms();
  }

  Future<void> _fetchChatRooms() async {
    try {
      final querySnapshot = await _firestore.collection('chats').get();
      setState(() {
        _chatRooms = querySnapshot.docs.where((doc) {
          return doc.id.contains('${widget.currentUserId}_') || doc.id.contains('_${widget.currentUserId}');
        }).toList();
      });
    } catch (e) {
      print('Error fetching chat rooms: $e');
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
    List<String> userIds = [widget.currentUserId, otherUserId];
    userIds.sort();
    String chatId = '${userIds[0]}_${userIds[1]}';

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
    print('Current User ID: ${widget.currentUserId}');
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
          ),
        ),
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
              child: _searchResults.isNotEmpty
                  ? ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user['username'][0].toUpperCase()),
                    ),
                    title: Text(user['username']),
                    onTap: () => _startChat(_searchResults[index].id, user['username']),
                  );
                },
              )
                  : ListView.builder(
                itemCount: _chatRooms.length,
                itemBuilder: (context, index) {
                  final chatId = _chatRooms[index].id;
                  final otherUserId = chatId.split('_').first == widget.currentUserId
                      ? chatId.split('_').last
                      : chatId.split('_').first;

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('users').doc(otherUserId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(title: Text('Loading...'));
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
                        return ListTile(title: Text('User not found'));
                      }
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