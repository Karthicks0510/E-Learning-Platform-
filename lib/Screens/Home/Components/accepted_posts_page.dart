import 'package:e_learning_platform/Screens/Home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AcceptedPostsPage extends StatefulWidget {
  @override
  _AcceptedPostsPageState createState() => _AcceptedPostsPageState();
}

class _AcceptedPostsPageState extends State<AcceptedPostsPage> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _acceptedPosts = [];
  bool _isLoading = true;
  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedPostId;
  Uint8List? _selectedFileBytes;
  Set<String> _uploadedPostIds = {}; // Track uploaded posts

  // Animation Controller for card scaling
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadAcceptedPosts();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAcceptedPosts() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final querySnapshot = await _firestore
            .collection('posts')
            .where('acceptedBy', isEqualTo: user.uid)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            _acceptedPosts = querySnapshot.docs;
          });
        }
      }
    } catch (e) {
      print('\x1B[31mError loading accepted posts: $e\x1B[0m');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectFile(String postId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          _selectedFileBytes = result.files.single.bytes;
          _selectedFileName = result.files.single.name;
          _selectedPostId = postId;
          _selectedFile = null;
        } else {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = path.basename(_selectedFile!.path);
          _selectedPostId = postId;
          _selectedFileBytes = null;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No file selected.'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  Future<void> _uploadSolution() async {
    final user = _auth.currentUser;

    if (user == null || (_selectedFile == null && _selectedFileBytes == null) || _selectedPostId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please select a file and ensure you are logged in."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final postDoc = await _firestore.collection('posts').doc(_selectedPostId).get();
    final postData = postDoc.data() as Map<String, dynamic>?;

    if (postData == null || postData['acceptedBy'] != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("You are not authorized to upload a solution."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (postData['deadline'] != null && DateTime.now().isAfter(postData['deadline'].toDate())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("The deadline for this post has passed."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      final postOwnerUid = postData['uid'];
      final postTitle = postData['title'] ?? 'Post'; // Get post title

      if (postOwnerUid == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Post owner UID not found."),
          backgroundColor: Colors.red,
        ));
        return;
      }

      String destination = 'users/$postOwnerUid/solutions/$_selectedPostId/$_selectedFileName';

      print("Selected Post ID: $_selectedPostId");
      print("Selected File Name: $_selectedFileName");
      print("Post Owner UID: $postOwnerUid");
      print("Destination: $destination");

      String fileUrl;
      if (kIsWeb) {
        print("Uploading bytes...");
        print(_selectedFileBytes);
        fileUrl = await Supabase.instance.client.storage
            .from('post-files')
            .uploadBinary(destination, _selectedFileBytes!);
      } else {
        print("Uploading file...");
        print(_selectedFile);
        fileUrl = await Supabase.instance.client.storage
            .from('post-files')
            .upload(destination, _selectedFile!);
      }

      fileUrl = Supabase.instance.client.storage.from('post-files').getPublicUrl(destination);

      print("File URL: $fileUrl");

      await _firestore.collection('posts').doc(_selectedPostId).update({
        'solutionUrl': fileUrl,
        'solutionUploaded': true,
        'status': 'Completed',
        'solutionTimestamp': FieldValue.serverTimestamp(),
      });

      print("Firestore update successful.");

      // Add notification to the post owner
      await FirebaseFirestore.instance.collection('notifications').doc(postOwnerUid).set({
        'notifications': FieldValue.arrayUnion([
          {
            'type': 'solution_uploaded',
            'message': 'A solution has been uploaded for your post "$postTitle"!',
            'timestamp': DateTime.now().toIso8601String(),
            'postId': _selectedPostId,
            'read': false,
          }
        ])
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solution uploaded successfully! Status changed to Completed.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
      // Send email after solution upload
      await _sendSolutionUploadedEmail(postOwnerUid, postData['title']);

      setState(() {
        _selectedFile = null;
        _selectedFileBytes = null;
        _selectedFileName = null;
        if (_selectedPostId != null) {
          _uploadedPostIds.add(_selectedPostId!);
        }
        _selectedPostId = null;
      });

    } catch (e) {
      print("Error during upload: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload solution: $e', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendSolutionUploadedEmail(String postOwnerUid, String postTitle) async {
    try {
      final userSnapshot = await _firestore.collection('users').doc(postOwnerUid).get();
      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        final postOwnerEmail = userData['email'];

        if (postOwnerEmail != null) {
          await _sendBrevoSolutionUploadedEmail(postOwnerEmail, postTitle);
        } else {
          print('Post owner email not found.');
        }
      } else {
        print('Post owner user document not found.');
      }
    } catch (e) {
      print('Error sending solution uploaded email: $e');
    }
  }

  Future<void> _sendBrevoSolutionUploadedEmail(String toEmail, String postTitle) async {
    final String apiKey = dotenv.env['BREVO_API_KEY']??''; // Replace with your Brevo API key
    final String apiUrl = dotenv.env["BREVO_URL"]??''; // Brevo API endpoint
    final String fromEmail = dotenv.env['ADMIN_EMAIL']??''; // Replace with your from email
    final String fromName = 'SkillSphere'; // Replace with your from name

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'api-key': apiKey,
        },
        body: jsonEncode(<String, dynamic>{
          'sender': {'email': fromEmail, 'name': fromName},
          'to': [
            {'email': toEmail}
          ],
          'subject': 'Solution Uploaded for Your Post!',
          'htmlContent': '<p>The solution for your post "$postTitle" has been uploaded. Please go through the solution and review it. We encourage you to provide feedback and mark the post as completed once you are satisfied. Thank you for using SkillSphere!</p>',
        }),
      );


      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Brevo email sent successfully');
        print('Brevo Response Status Code: ${response.statusCode}');
        print('Brevo Response Body: ${utf8.decode(response.bodyBytes)}'); // Decode the response body
      } else {
        print('Failed to send Brevo email');
        print('Brevo Response Status Code: ${response.statusCode}');
        print('Brevo Response Body: ${utf8.decode(response.bodyBytes)}'); // Decode the response body
      }

    } catch (e) {
      print('Error sending solution uploaded email via Brevo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accepted Posts',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => HomeScreen()));
          },
        ),
        elevation: 2,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
            valueColor:
            AlwaysStoppedAnimation<Color>(Colors.deepPurple)),
      )
          : _acceptedPosts.isEmpty
          ? _buildEmptyState()
          : _buildPostGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_unread_rounded, size: 60, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text('No accepted posts yet.',
              style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700])),
          SizedBox(height: 10),
          Text(
            "Check back later for updates!",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 900
            ? 4 // 4 cards in a row for very large screens (e.g., tablets, desktops)
            : MediaQuery.of(context).size.width > 600
            ? 3 // 3 cards in a row for medium screens (e.g., landscape tablets)
            : 2, // Default to 2 cards in a row for smaller screens (e.g., phones)
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1 : 0.9,
      ),
      itemCount: _acceptedPosts.length,
      itemBuilder: (context, index) {
        final post = _acceptedPosts[index].data() as Map<String, dynamic>?;
        final postId = _acceptedPosts[index].id;
        if (post == null) return SizedBox.shrink();
        final deadline = post['deadline'] != null ? post['deadline'].toDate() : null;
        final isExpired = deadline != null && DateTime.now().isAfter(deadline);
        final solutionUploaded = post['solutionUploaded'] == true;

        return ConstrainedBox( // Added ConstrainedBox
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 600 ? 400 : 350, // Set max width dynamically
          ),
          child: _buildPostCard(context, post, postId, deadline, isExpired, solutionUploaded),
        );
      },
    );
  }

  Widget _buildPostCard(
      BuildContext context,
      Map<String, dynamic> post,
      String postId,
      DateTime? deadline,
      bool isExpired,
      bool solutionUploaded) {
    return GestureDetector(
        onTap: () {
          print('Card Tapped: ${post['title']}');
          _animationController.forward().then((_) => _animationController.reverse());
        },
        child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(
                        children: [
                        Icon(
                        Icons.lightbulb,
                          size: 28,
                          color: isExpired
                              ? Colors.grey[500]
                              : solutionUploaded
                              ? Colors.green
                              : Colors.deepPurple,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            post['title'] ?? 'No Title',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w800,
                              color: isExpired
                                  ? Colors.grey[700]!
                                  : solutionUploaded
                                  ? Colors.green
                                  : Colors.deepPurple,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.0),
                    Row(
                      children: [
                        Icon(Icons.label_important_outline_rounded,
                            size: 18, color: Colors.grey[500]),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Status: ${post['status'] ?? 'Pending'}',
                            style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (deadline != null)
                Row(
                children: [
                Icon(Icons.event_rounded,
                size: 18, color: Colors.grey[500]),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Deadline: ${DateFormat('yyyy-MM-dd HH:mm').format(deadline)}',
                style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            )],
            ),
            if (solutionUploaded)
        Row(
        children: [
        Icon(Icons.verified_user_rounded,
        size: 18, color: Colors.green),
    SizedBox(width: 6),
    Expanded(
    child: Text(
    'Solution Uploaded',
    style: TextStyle(
    color: Colors.green,
    fontWeight: FontWeight.w700),
    overflow: TextOverflow.ellipsis,
    ),
    )],
    ),
    if (isExpired)
    Row(
    children: [
    Icon(Icons.alarm_off_rounded,
    size: 18, color: Colors.red),
    SizedBox(width: 6),
    Expanded(
    child: Text(
    'Post Expired',
    style: TextStyle(
    color: Colors.red,
    fontWeight: FontWeight.w700),
    overflow: TextOverflow.ellipsis,
    ),
    )],
    ),
    ],
    ),
    if (!isExpired && !solutionUploaded)
    Align(
    alignment: Alignment.bottomRight,
    child: (_selectedPostId == postId &&
    (_selectedFile != null || _selectedFileBytes != null))
    ? Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
    Text(
    'Selected File: $_selectedFileName',
    style: TextStyle(fontSize: 14),
    overflow: TextOverflow.ellipsis,
    ),
    SizedBox(height: 8),
    ElevatedButton.icon(
    onPressed: _uploadSolution,
    icon: Icon(Icons.cloud_upload_rounded,
    color: Colors.white),
    label: Text('Submit',
    style: TextStyle(color: Colors.white)),
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12)),
    padding: EdgeInsets.symmetric(
    horizontal: 16, vertical: 12),
    ),
    ),
    ],
    )
        : ElevatedButton.icon(
    onPressed: () => _selectFile(postId),
    icon: Icon(Icons.attach_file_rounded,
    color: Colors.white),
    label: Text('Select File',
    style: TextStyle(color: Colors.white)),
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12)),
    padding: EdgeInsets.symmetric(
    horizontal: 16, vertical: 12),
    ),
    ),
    ),
    ],
    ),
    ),
    ),
    ),
    );
    }

}
