import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PostDetailsPage extends StatefulWidget {
  final String postId;

  PostDetailsPage({required this.postId});

  @override
  _PostDetailsPageState createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  User? user = FirebaseAuth.instance.currentUser;

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> acceptPost(BuildContext context) async {
    try {
      final accepterUid = FirebaseAuth.instance.currentUser?.uid;
      if (accepterUid == null) {
        print("User not logged in.");
        return;
      }

      final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
      final acceptedAt = FieldValue.serverTimestamp();
      final deadline = Timestamp.fromDate(DateTime.now().add(const Duration(hours: 3)));

      await postRef.update({
        'acceptedBy': accepterUid,
        'status': 'Accepted',
        'acceptedAt': acceptedAt,
        'deadline': deadline,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post accepted successfully!')),
      );

      setState(() {}); // Refresh the UI after acceptance
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting post: $e')),
      );
    }
  }

  Future<void> handleTimerExpiration(String postId) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

      await postRef.update({
        'status': 'Expired', // or 'Failed', 'Overdue'
        'acceptedBy': null,
      });

      print('Post status updated to Expired.');
      setState(() {}); // Refresh the UI after timer expires
    } catch (e) {
      print('Error updating post status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: timer expiration failed. $e')),
      );
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
        future: FirebaseFirestore.instance.collection('posts').doc(widget.postId).get(),
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
          String status = data['status'] ?? 'Pending';
          Timestamp? deadline = data['deadline'];
          String postOwnerUid = data['uid'];
          String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
          String acceptedBy = data['acceptedBy'] ?? '';

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
                                // Display Status at the Top
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.info, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Status: $status',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20),
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
                                if (status == 'Accepted' && deadline != null)
                                  _buildTimer(deadline)
                                else if (status == 'Pending' && postOwnerUid != currentUserId)
                                  acceptedBy.isNotEmpty
                                      ? Container(
                                    child: Text("Accepted by another user.", style: TextStyle(color: Colors.white)),
                                  )
                                      : _buildAcceptButton(context)
                                else if (postOwnerUid == currentUserId)
                                    Text("This is your post.", style: TextStyle(color: Colors.white))
                                  else
                                    Text('Status: $status', style: TextStyle(color: Colors.white)),
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

  Widget _buildAcceptButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => acceptPost(context),
        child: Text('Accept', style: TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildTimer(Timestamp deadline) {
    return CountdownTimer(postId: widget.postId);
  }
}

class CountdownTimer extends StatefulWidget {
  final String postId;

  const CountdownTimer({super.key, required this.postId});

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Duration _remainingTime = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final postData = snapshot.data!.data() as Map<String, dynamic>;
          final deadline = postData['deadline'] as Timestamp?;

          if (deadline != null) {
            _remainingTime = deadline.toDate().difference(DateTime.now());

            if (_remainingTime.isNegative) {
              _timer?.cancel();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                handleTimerExpiration(widget.postId,context);
              });
              return const Text(
                  'Time expired!', style: TextStyle(color: Colors.red));
            }

            if (_timer == null || !_timer!.isActive) {
              _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (mounted) {
                  setState(() {
                    _remainingTime =
                        deadline.toDate().difference(DateTime.now());
                    if (_remainingTime.isNegative) {
                      timer.cancel();
                    }
                  });
                } else {
                  timer.cancel();
                }
              });
            }

            return Text(
              '${_remainingTime.inHours.toString().padLeft(
                  2, '0')}:${(_remainingTime.inMinutes % 60).toString().padLeft(
                  2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(
                  2, '0')}',
              style: const TextStyle(color: Colors.white),
            );
          } else {
            return const Text(
                'Deadline not set.', style: TextStyle(color: Colors.white));
          }
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  Future<void> handleTimerExpiration(String postId, BuildContext context) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
      final postSnapshot = await postRef.get();
      final postData = postSnapshot.data() as Map<String, dynamic>;

      // Check if the post status is already 'Pending'
      if (postData['status'] == 'Pending') {
        print('Post status is already Pending.');
        return; // Exit if already Pending
      }

      // Check if a solution has been uploaded (if you have a 'solutionUploaded' field)
      if (postData['solutionUploaded'] == null || !postData['solutionUploaded']) {
        await postRef.update({
          'status': 'Pending', // Update status to Pending
          'acceptedBy': null,
          'deadline': null, // Remove deadline if you want to reset it
          'acceptedAt': null, // Remove accepted time if you want to reset it
        });

        print('Post status updated to Pending.');
        if (mounted) {
          setState(() {});
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The post deadline expired. Post status reset to Pending.')),
        );
      } else {
        print('Solution was uploaded, no status change.');
        // Optionally, you can set a different status here (e.g., 'Completed') if a solution was uploaded.
        // await postRef.update({'status': 'Completed'});
        if (mounted) {
          setState(() {});
        }
      }

    } catch (e) {
      print('Error updating post status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: timer expiration failed. $e')),
        );
      }
    }
  }
}
