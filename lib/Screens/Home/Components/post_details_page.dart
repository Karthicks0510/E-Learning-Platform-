import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PostDetailsPage extends StatelessWidget {
  final String postId;

  PostDetailsPage({required this.postId});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
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
          List<String> attachments = List<String>.from(data['attachments'] ?? []);

          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[800]!, Colors.purple[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 600),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTitleSection(data['title'] ?? 'No Title'),
                                SizedBox(height: 20),
                                _buildDetailItem(Icons.description, 'Description', data['description'] ?? 'No Description'),
                                SizedBox(height: 10),
                                _buildDetailItem(Icons.attach_money, 'Rewards', '${data['rewards'] ?? 'N/A'} ${data['currency'] ?? ''}'),
                                SizedBox(height: 10),
                                _buildDetailItem(Icons.language, 'Preferred Languages', data['preferredLanguages'] != null ? data['preferredLanguages'].join(', ') : 'None'),
                                SizedBox(height: 10),
                                if (attachments.isNotEmpty)
                                  _buildAttachmentSection(attachments)
                                else
                                  _buildDetailItem(Icons.attachment, 'Attachments', 'No attachments available.'),
                                SizedBox(height: 20),
                                _buildAcceptButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTitleSection(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                SizedBox(height: 4),
                Text(value, style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection(List<String> attachments) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attachment, color: Colors.white70, size: 28),
              SizedBox(width: 20),
              Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: attachments.map((url) {
              return IconButton(
                icon: Icon(Icons.remove_red_eye, color: Colors.white),
                onPressed: () => _launchUrl(url),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {},
        child: Text('Accept', style: TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }
}