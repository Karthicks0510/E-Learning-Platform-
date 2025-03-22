import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_room_screen.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;

  ChatScreen({required this.currentUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildRecentChats()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search Users',
          prefixIcon: Icon(Icons.search, color: Colors.purple),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.trim());
        },
      ),
    );
  }

  Widget _buildRecentChats() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: widget.currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        var chats = snapshot.data!.docs;

        if (chats.isEmpty) return Center(child: Text('No recent chats'));

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            var chat = chats[index].data() as Map<String, dynamic>;
            var otherUserId = chat['participants'].firstWhere((id) => id != widget.currentUserId);

            return FutureBuilder(
              future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return SizedBox.shrink();
                var userData = userSnapshot.data!.data() as Map<String, dynamic>;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(userData['profilePicture'] ?? 'https://via.placeholder.com/150'),
                      radius: 24,
                    ),
                    title: Text(userData['username'] ?? 'Unknown User', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(chat['lastMessage'] ?? 'Start chatting now!'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomScreen(
                            chatRoomId: chats[index].id,
                            chatPartnerId: otherUserId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: _searchQuery)
          .where('username', isLessThan: _searchQuery + 'z')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        var users = snapshot.data!.docs;

        if (users.isEmpty) return Center(child: Text('No users found'));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index].data() as Map<String, dynamic>;
            var userId = users[index].id;

            if (userId == widget.currentUserId) return SizedBox.shrink();

            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user['profilePicture'] ?? 'https://via.placeholder.com/150'),
                  radius: 24,
                ),
                title: Text(user['username'] ?? 'Unknown'),
                onTap: () async {
                  String chatRoomId = widget.currentUserId.hashCode <= userId.hashCode
                      ? '${widget.currentUserId}_$userId'
                      : '${userId}_${widget.currentUserId}';

                  await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
                    'participants': [widget.currentUserId, userId],
                    'lastMessage': '',
                    'timestamp': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        chatRoomId: chatRoomId,
                        chatPartnerId: userId,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}