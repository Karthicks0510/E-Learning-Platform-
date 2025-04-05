// feedback_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackPage extends StatefulWidget {
  final String userId;
  FeedbackPage({required this.userId});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Give Feedback', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(20.0), // Increased padding
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: 'Your Comment', // More user-friendly label
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15), // More rounded corners
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                      ),
                      prefixIcon: Icon(Icons.comment, color: Colors.deepPurple), // Added icon
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a comment';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30), // Increased spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Rating: ${_rating.toStringAsFixed(1)}', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 20),
                      Expanded( // Make slider responsive
                        child: Slider(
                          value: _rating,
                          onChanged: (value) {
                            setState(() {
                              _rating = value;
                            });
                          },
                          min: 0,
                          max: 5,
                          divisions: 5,
                          label: _rating.toString(),
                          activeColor: Colors.amber, // Changed active color
                          inactiveColor: Colors.grey[300],
                        ),
                      ),
                      Icon(Icons.star, color: Colors.amber), // Added star icon
                    ],
                  ),
                  SizedBox(height: 30),
                  ElevatedButton.icon( // Used ElevatedButton.icon
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _saveFeedback();
                      }
                    },
                    icon: Icon(Icons.send, color: Colors.white), // Added send icon
                    label: Text('Submit Feedback', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      textStyle: TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveFeedback() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final username = userDoc.data()?['username'] ?? 'Unknown';
      final profileUrl = userDoc.data()?['profile_url'];

      await FeedbackService.saveFeedback(
        userId: widget.userId,
        comment: _commentController.text,
        rating: _rating,
        fromUsername: username,
        fromProfileUrl: profileUrl,
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save feedback', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class FeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveFeedback({
    required String userId,
    required String comment,
    required double rating,
    required String fromUsername,
    String? fromProfileUrl,
  }) async {
    try {
      await _firestore
          .collection('feedbacks')
          .doc(userId)
          .collection('comments')
          .doc(_firestore.collection('users').doc().id)
          .set({
        'comment': comment,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
        'fromUsername': fromUsername,
        'fromProfileUrl': fromProfileUrl,
      });

      await _updateAverageRating(userId);

    } catch (e) {
      print('Error saving feedback: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getFeedback({required String userId}) async {
    try {
      final feedbackSnapshot = await _firestore
          .collection('feedbacks')
          .doc(userId)
          .collection('comments')
          .get();

      return feedbackSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error loading feedback: $e');
      return [];
    }
  }

  static Future<void> _updateAverageRating(String userId) async {
    try {
      final feedbackSnapshot = await _firestore.collection('feedbacks').doc(userId).collection('comments').get();

      if (feedbackSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in feedbackSnapshot.docs) {
          totalRating += (doc.data()['rating'] as num).toDouble();
        }
        double averageRating = totalRating / feedbackSnapshot.docs.length;

        await _firestore.collection('feedbacks').doc(userId).update({
          'averageRating': averageRating,
          'totalReviews': feedbackSnapshot.docs.length,
        });
      } else {
        await _firestore.collection('feedbacks').doc(userId).update({
          'averageRating': 0.0,
          'totalReviews': 0,
        });
      }
    } catch (e) {
      print("Error updating average rating: $e");
    }
  }
}