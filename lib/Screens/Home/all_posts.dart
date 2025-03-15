import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';

class AllPosts extends StatefulWidget {
  @override
  _AllPostsState createState() => _AllPostsState();
}

class _AllPostsState extends State<AllPosts> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No posts yet.'));
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth > 600 ? 300.0 : 200.0;
              return Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: snapshot.data!.docs.map((document) {
                  Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
                  return SizedBox(
                    width: cardWidth,
                    child: PostItem(data: data, document: document),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }
}

class PostItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final DocumentSnapshot document;

  const PostItem({Key? key, required this.data, required this.document})
      : super(key: key);

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  FadeTransition(
                    opacity: animation,
                    child: PostDetailsPage(postId: widget.document.id),
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: Duration(milliseconds: 300),
            ),
          );
        },
        onHover: (isHovering) {
          setState(() {
            _isHovering = isHovering;
          });
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 5), //Removed horizontal margin
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isHovering
                  ? [Colors.blue[600]!, Colors.purple[600]!]
                  : [Colors.blue[400]!, Colors.purple[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(_isHovering ? 0.7 : 0.5),
                spreadRadius: _isHovering ? 3 : 2,
                blurRadius: _isHovering ? 7 : 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInLeft(
                child: Text(
                  widget.data['title'] ?? 'No Title',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8),
              FadeInLeft(
                child: Row(
                  children: [
                    Icon(Icons.diamond, color: Colors.yellow),
                    SizedBox(width: 4),
                    Text(
                      'Rewards: ${widget.data['rewards'] ?? 'N/A'} ${widget.data['currency'] ?? ''}',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // You can add more elements here (e.g., description)
            ],
          ),
        ),
      ),
    );
  }
}

class PostDetailsPage extends StatelessWidget {
  final String postId;

  PostDetailsPage({required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
        backgroundColor: Colors.purple,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
        FirebaseFirestore.instance.collection('posts').doc(postId).get(),
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

          Map<String, dynamic> data =
          snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInLeft(
                  child: Text('Title: ${data['title'] ?? 'No Title'}',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 10),
                FadeInLeft(
                  child: Text(
                      'Description: ${data['description'] ?? 'No Description'}'),
                ),
                SizedBox(height: 10),
                FadeInLeft(
                  child: Text(
                      'Rewards: ${data['rewards'] ?? 'N/A'} ${data['currency'] ?? ''}'),
                ),
                SizedBox(height: 10),
                FadeInLeft(
                  child: Row(
                    children: [
                      Text('Attachments: '),
                      IconButton(
                        icon: Icon(Icons.remove_red_eye),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                Text('Attachment view not implemented yet.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: FadeInUp(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                              Text('Accept button not implemented yet.')),
                        );
                      },
                      child: Text('Accept'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}