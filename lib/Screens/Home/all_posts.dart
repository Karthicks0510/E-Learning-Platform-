import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'components/post_details_page.dart';

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
          return Center(
              child: Text('Something went wrong', style: GoogleFonts.openSans()));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No posts yet.', style: GoogleFonts.openSans()));
        }
    
        // Filter out posts with status 'completed'
        final filteredDocs = snapshot.data!.docs
            .where((document) =>
        (document.data() as Map<String, dynamic>)['status'] !=
            'Completed')
            .toList();

        if (filteredDocs.isEmpty) {
          return Center(
              child: Text('No active posts available.',
                  style: GoogleFonts.openSans()));
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth > 600 ? 300.0 : 200.0;
              return SingleChildScrollView(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: filteredDocs.map((document) {
                    Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;
                    return SizedBox(
                      width: cardWidth,
                      child: PostItem(data: data, document: document),
                    );
                  }).toList(),
                ),
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
          margin: EdgeInsets.symmetric(vertical: 5),
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
                  style: GoogleFonts.openSans(
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
                      style: GoogleFonts.openSans(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}