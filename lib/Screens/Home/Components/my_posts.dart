import 'package:e_learning_platform/Screens/Home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_details_page.dart';
import 'edit_post_page.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPostsScreen extends StatelessWidget {
  final SupabaseClient supabase = Supabase.instance.client;

  MyPostsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('My Posts', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.purple,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(child: Text('Please log in to view your posts.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen())),
        ),
        title: Text('My Posts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('uid', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('You have no posts.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final document = snapshot.data!.docs[index];
              final data = document.data() as Map<String, dynamic>;

              return _buildPostCard(context, data, document.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> data, String postId) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: Card(
          margin: EdgeInsets.all(8.0),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'No Title',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Rewards: ${data['rewards'] ?? 'N/A'}'),
                SizedBox(height: 8),
                Text('Status: ${data['status'] ?? 'Pending'}'),
                if (data['solutionUrl'] != null && data['solutionUrl'].isNotEmpty)
                  TextButton(
                    onPressed: () => _launchURL(data['solutionUrl']),
                    child: Text('View Solution'),
                  ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailsPage(postId: postId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size(80, 45),
                        ),
                        child: Text('Read More', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPostPage(postId: postId),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _showDeleteConfirmation(context, postId, data['imageUrl']),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String postId, String? imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => _deletePost(context, postId, imageUrl),
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost(BuildContext context, String postId, String? imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        Uri uri = Uri.parse(imageUrl);
        String fileName = uri.pathSegments.last;
        await supabase.storage.from('posts').remove([fileName]);
      }
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post deleted successfully.')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete post.')));
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }
}