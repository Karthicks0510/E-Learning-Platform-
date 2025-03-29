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

class AcceptedPostsPage extends StatefulWidget {
  @override
  _AcceptedPostsPageState createState() => _AcceptedPostsPageState();
}

class _AcceptedPostsPageState extends State<AcceptedPostsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _acceptedPosts = [];
  bool _isLoading = true;
  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedPostId;
  Uint8List? _selectedFileBytes;
  Set<String> _uploadedPostIds = {}; // Track uploaded posts

  @override
  void initState() {
    super.initState();
    _loadAcceptedPosts();
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solution uploaded successfully! Status changed to Completed.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedFile = null;
        _selectedFileBytes = null;
        _selectedFileName = null;
        _selectedPostId = null;
        _uploadedPostIds.add(_selectedPostId!); // Add post ID to uploaded set
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accepted Posts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=>HomeScreen()));
          },
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)))
          : _acceptedPosts.isEmpty
          ? Center(child: Text('No accepted posts yet.', style: TextStyle(fontSize: 16.0, color: Colors.grey[600])))
          : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1 : 0.8,
        ),
        itemCount: _acceptedPosts.length,
        itemBuilder: (context, index) {
          final post = _acceptedPosts[index].data() as Map<String, dynamic>?;
          final postId = _acceptedPosts[index].id;
          if (post == null) return SizedBox.shrink();
          final deadline = post['deadline'] != null ? post['deadline'].toDate() : null;
          final isExpired = deadline != null && DateTime.now().isAfter(deadline);
          final solutionUploaded = post['solutionUploaded'] == true; // Check if solution is uploaded

          return Card(
            margin: EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 4.0,
            color: isExpired ? Colors.grey[300]! : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['title'] ?? 'No Title',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: isExpired ? Colors.grey[600]! : Colors.deepPurple,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.0),
                  Text('Status: ${post['status'] ?? 'Pending'}', style: TextStyle(color: Colors.grey[700])),
                  if (deadline != null)
                    Text('Deadline: ${deadline}', style: TextStyle(color: Colors.grey[700])),
                  if (solutionUploaded)
                    Text('Solution Uploaded', style: TextStyle(color: Colors.green)),
                  if (isExpired)
                    Text('Post Expired', style: TextStyle(color: Colors.red)),
                  Spacer(),
                  if (!isExpired && !solutionUploaded) // Show buttons only if not expired and solution not uploaded
                    (_selectedPostId == postId && (_selectedFile != null || _selectedFileBytes != null)
                        ? Column(
                      children: [
                        Text('Selected File: $_selectedFileName', style: TextStyle(fontSize: 14)),
                        ElevatedButton(
                          onPressed: _uploadSolution,
                          child: Text('Submit Solution', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ],
                    )
                        : ElevatedButton(
                      onPressed: () => _selectFile(postId),
                      child: Text('Select Solution', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}