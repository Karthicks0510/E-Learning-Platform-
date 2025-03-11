import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(userId)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No notifications.'));
            }
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var notification = snapshot.data!.docs[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: notification['senderProfilePicture'] != null
                        ? NetworkImage(notification['senderProfilePicture'])
                        : AssetImage('assets/default_profile.png') as ImageProvider, // Replace with your default asset path
                  ),
                  title: Text('${notification['senderUsername']} created a new post.'),
                  subtitle: Text(
                      '${DateTime.fromMillisecondsSinceEpoch(notification['timestamp'].millisecondsSinceEpoch)}'),
                  onTap: () async {
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(userId)
                        .collection('notifications')
                        .doc(notification.id)
                        .update({'isRead': true});
                    // Navigate to the post details page if necessary.
                  },
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications.'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class NotificationBell extends StatefulWidget {
  @override
  _NotificationBellState createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final unreadCount = snapshot.data!.docs.length;
          return Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationScreen()),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        } else {
          return IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          );
        }
      },
    );
  }
}