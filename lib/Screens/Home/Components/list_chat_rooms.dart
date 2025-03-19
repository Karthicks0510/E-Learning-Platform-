import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading chats'));
          }

          final chatDocs = snapshot.data!.docs.where((doc) {
            String docId = doc.id;
            return docId.contains('${currentUserId}_') || docId.contains('_${currentUserId}');
          }).toList();

          if (chatDocs.isEmpty) {
            return Center(child: Text('No chats found'));
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatId = chatDocs[index].id;
              List<String> userIds = chatId.split('_');
              String otherUserId = userIds[0] == currentUserId ? userIds[1] : userIds[0];

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(title: Text('Loading...'));
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(title: Text('User not found'));
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(userData['username'][0].toUpperCase())),
                      title: Text(userData['username']),
                      subtitle: Text('Tap to open chat'),
                      onTap: () {
                        // Navigate to chat room (Add chat room screen navigation here)
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
