import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostDetailsPage extends StatelessWidget {
  final String postId;

  PostDetailsPage({required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
        backgroundColor: Colors.deepPurple, // Changed color to deepPurple
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('posts').doc(postId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || !snapshot.data!.exists) {
            return Center(child: Text('Post not found.'));
          }

          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView( // Added SingleChildScrollView
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with larger font size and bold
                  Text(
                    data['title'] ?? 'No Title',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),

                  // Description with divider
                  Text('Description:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Divider(thickness: 2),
                  SizedBox(height: 8),
                  Text(data['description'] ?? 'No Description'),
                  SizedBox(height: 16),

                  // Rewards section with Card decoration
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rewards:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('${data['rewards'] ?? 'N/A'} ${data['currency'] ?? ''}', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Attachments section with icon
                  Row(
                    children: [
                      Icon(Icons.attachment, size: 20),
                      SizedBox(width: 8),
                      Text('Attachments:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  // You can add your attachment display logic here
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Attachment view not implemented yet.')),
                      );
                    },
                    child: Text('View Attachments'),
                  ),
                  SizedBox(height: 32),

                  // Accept button with styling
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Changed button color to green
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Accept button not implemented yet.')),
                        );
                      },
                      child: Text('Accept'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}