import 'package:e_learning_platform/Screens/Home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_room_screen.dart';
import 'package:google_fonts/google_fonts.dart';

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
        title: Text(
          'Chats',
          style: GoogleFonts.openSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen())),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                _buildSearchBar(constraints),
                Expanded(
                  child: _searchQuery.isEmpty
                      ? _buildRecentChats(constraints)
                      : _buildSearchResults(constraints),
                ),
              ],
            );
          },
        ),
      ),
      backgroundColor: Colors.deepPurple[50],
    );
  }

  Widget _buildSearchBar(BoxConstraints constraints) {
    return Padding(
      padding: EdgeInsets.all(constraints.maxWidth * 0.03),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search Users',
            labelStyle: GoogleFonts.openSans(),
            prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value.trim());
          },
        ),
      ),
    );
  }

  Widget _buildRecentChats(BoxConstraints constraints) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: widget.currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: Colors.deepPurple));
        var chats = snapshot.data!.docs;

        if (chats.isEmpty) return Center(child: Text('No recent chats', style: GoogleFonts.openSans()));

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                var chat = chats[index].data() as Map<String, dynamic>;
                if (chat['participants'] == null || chat['participants'].isEmpty) {
                  return SizedBox.shrink();
                }

                var otherUserId = chat['participants'].firstWhere((id) => id != widget.currentUserId);

                return FutureBuilder(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) return SizedBox.shrink();
                    var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    if (userData == null) {
                      return SizedBox.shrink();
                    }

                    return Card(
                      elevation: 5,
                      margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.03, vertical: constraints.maxHeight * 0.01),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.account_circle,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          radius: constraints.maxWidth > 0 ? constraints.maxWidth * 0.06 : 20,
                        ),
                        title: Text(userData['username'] ?? 'Unknown User', style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
                        subtitle: Text(chat['lastMessage'] ?? 'Start chatting now!', style: GoogleFonts.openSans()),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(BoxConstraints constraints) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: _searchQuery)
          .where('username', isLessThan: _searchQuery + 'z')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: Colors.deepPurple));
        var users = snapshot.data!.docs;

        if (users.isEmpty) return Center(child: Text('No users found', style: GoogleFonts.openSans()));

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                var user = users[index].data() as Map<String, dynamic>;
                var userId = users[index].id;

                if (userId == widget.currentUserId) return SizedBox.shrink();

                return Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.03, vertical: constraints.maxHeight * 0.01),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.account_circle,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      radius: constraints.maxWidth > 0 ? constraints.maxWidth * 0.06 : 20,
                    ),
                    title: Text(user['username'] ?? 'Unknown', style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
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
            ),
          ),
        );
      },
    );
  }
}