// my_posts.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyPostsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text("Please log in to view your posts."));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("My Posts"),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('uid', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Something went wrong."));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text("You have no posts yet."));
          }

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: snapshot.data!.docs.length,
            padding: EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              Map<String, dynamic> data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  onTap: () {
                    _showFullPost(
                      context,
                      data['title'] ?? "No Title",
                      data['description'] ?? "No Description",
                      data['rewards'] ?? "N/A",
                      data['attachment'] ?? "",
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? "No Title",
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Reward: ${data['rewards'] ?? "N/A"}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Expanded(
                          child: Text(
                            data['description'] ?? "No Description",
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _showFullPost(
                                  context,
                                  data['title'] ?? "No Title",
                                  data['description'] ?? "No Description",
                                  data['rewards'] ?? "N/A",
                                  data['attachment'] ?? "",
                                );
                              },
                              child: Text(
                                "Read More",
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFullPost(
      BuildContext context, String title, String description, String reward, String attachment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          titlePadding: EdgeInsets.all(16.0),
          contentPadding: EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reward: $reward', style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 16.0),
                Text("Description:"),
                SizedBox(height: 8.0),
                Text(description),
                SizedBox(height: 16.0),
                if (attachment.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.grey),
                      SizedBox(width: 8.0),
                      InkWell(
                        onTap: () {
                          // TODO: Implement logic to view attachment
                          print("View attachment: $attachment");
                        },
                        child: Text(
                          attachment,
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}