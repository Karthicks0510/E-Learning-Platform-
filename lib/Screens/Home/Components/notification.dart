import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationBell extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('notifications').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final notifications = List<Map<String, dynamic>>.from(snapshot.data!['notifications'] ?? []);
          final unreadCount = notifications.where((notification) => !notification['read']).length;

          return Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_active, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationsPage()),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
                MaterialPageRoute(builder: (context) => NotificationsPage()),
              );
            },
          );
        }
      },
    );
  }
}

class NotificationsPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('notifications').doc(userId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong', style: TextStyle(color: Colors.red)));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('No notifications', style: TextStyle(fontSize: 18)));
            }

            final notifications = List<Map<String, dynamic>>.from(snapshot.data!['notifications'] ?? []);

            // Separate read and unread notifications
            final unreadNotifications = notifications.where((notification) => !notification['read']).toList();
            final readNotifications = notifications.where((notification) => notification['read']).toList();

            return ListView(
              children: [
                if (unreadNotifications.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Unread Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  ...unreadNotifications.map((notification) {
                    final timestamp = DateTime.parse(notification['timestamp']);
                    final formattedDate = DateFormat('MMM d, yyyy - HH:mm').format(timestamp);

                    return ListTile(
                      leading: Icon(Icons.notifications_active, color: Colors.deepPurple),
                      title: Text(notification['message'], style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(formattedDate),
                      trailing: Icon(Icons.circle, color: Colors.blue),
                      onTap: () async {
                        await FirebaseFirestore.instance.collection('notifications').doc(userId).update({
                          'notifications': FieldValue.arrayUnion([
                            {
                              'type': notification['type'],
                              'message': notification['message'],
                              'timestamp': notification['timestamp'],
                              'postId': notification['postId'],
                              'read': true,
                            }
                          ]),
                          'notifications': FieldValue.arrayRemove([notification])
                        });
                      },
                    );
                  }).toList(),
                ],
                if (readNotifications.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Read Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  ...readNotifications.map((notification) {
                    final timestamp = DateTime.parse(notification['timestamp']);
                    final formattedDate = DateFormat('MMM d, yyyy - HH:mm').format(timestamp);

                    return ListTile(
                      leading: Icon(Icons.notifications, color: Colors.grey),
                      title: Text(notification['message'], style: TextStyle(color: Colors.grey)),
                      subtitle: Text(formattedDate, style: TextStyle(color: Colors.grey)),
                    );
                  }).toList(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}