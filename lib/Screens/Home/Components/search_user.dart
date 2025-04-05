// search_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../home_screen.dart';
import 'feedback_service.dart'; // Import the feedback_page.dart

class SearchUser extends StatefulWidget {
  @override
  _SearchUserState createState() => _SearchUserState();
}

class _SearchUserState extends State<SearchUser> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  void searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> results = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).where((user) {
        String username = user['username']?.toString().toLowerCase() ?? '';
        print('Checking username: $username, query: ${query.toLowerCase()}'); // Debugging
        return username.contains(query.toLowerCase());
      }).toList();

      setState(() {
        _searchResults = results;
        print('Search Results: $_searchResults'); // Debugging
      });
    } catch (e) {
      print('Error searching users: $e');
      // Display an error message to the user if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomeScreen()));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => HomeScreen()));
            },
          ),
          title: Text("Search Users", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.deepPurple, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: TextField(
                        controller: _searchController,
                        onChanged: searchUsers,
                        decoration: InputDecoration(
                          hintText: 'Search Users...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey.shade500),
                            onPressed: () {
                              _searchController.clear();
                              searchUsers('');
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 600),
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: FadeInLeft(
                            child: UserFeedbackCard(userId: user['id']),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// UserFeedbackCard Widget
class UserFeedbackCard extends StatefulWidget {
  final String userId;

  UserFeedbackCard({required this.userId});

  @override
  _UserFeedbackCardState createState() => _UserFeedbackCardState();
}

class _UserFeedbackCardState extends State<UserFeedbackCard> {
  List<Map<String, dynamic>> _userFeedback = [];
  Map<String, dynamic>? _userData;
  bool _showFeedback = false; // Controls visibility of feedback

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadFeedback() async {
    try {
      final feedbackSnapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          .doc(widget.userId)
          .collection('comments')
          .get();

      setState(() {
        _userFeedback = feedbackSnapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error loading feedback: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (_userData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(userData: _userData!),
            ),
          );
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _userData?['profile_url'] != null
                      ? NetworkImage(_userData!['profile_url'])
                      : null,
                  child: _userData?['profile_url'] == null
                      ? Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                title: Text(_userData?['username'] ?? 'Unknown'),
                subtitle: Text(_userData?['designation'] ?? 'No Designation'),
                trailing: SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeedbackPage(userId: widget.userId),
                        ),
                      );
                    },
                    child: Text('Feedback'),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Show Feedback Button (Responsive)
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 200), // Limit button width
                  child: ElevatedButton(
                    onPressed: () {
                      if (!_showFeedback) {
                        _loadFeedback(); // Load feedback only when first clicked
                      }
                      setState(() {
                        _showFeedback = !_showFeedback;
                      });
                    },
                    child: Text(_showFeedback ? 'Hide Feedback' : 'Show Feedback'),
                  ),
                ),
              ),

              // Display feedback only if _showFeedback is true
              if (_showFeedback) ...[
                SizedBox(height: 10),
                Text('Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                _userFeedback.isEmpty
                    ? Text('No feedback yet.')
                    : Column(
                  children: _userFeedback.map((feedback) {
                    return Card(
                      child: ListTile(
                        title: Text(feedback['comment'] ?? 'No Comment'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rating: ${feedback['rating'] ?? 'N/A'}'),
                            Text('From: ${feedback['fromUsername'] ?? 'Unknown'}'),
                            Text(
                              'Date: ${feedback['timestamp']?.toDate() ?? 'N/A'}',
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// UserProfilePage Widget
// user_profile_page.dart


class UserProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;

  UserProfilePage({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userData['username'] ?? 'Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple, // App theme color
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.deepPurple.shade50, // Light background variant
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center alignment
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 80,
                backgroundImage: userData['profile_url'] != null
                    ? NetworkImage(userData['profile_url'])
                    : null,
                child: userData['profile_url'] == null
                    ? Icon(Icons.person, size: 80, color: Colors.white)
                    : null,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            SizedBox(height: 24),
            _buildProfileSection(
              title: 'Personal Information',
              children: [
                _buildProfileDetail('Name', userData['name']),
                _buildProfileDetail('Username', userData['username']),
                _buildProfileDetail('Email', userData['email']),
              ],
            ),
            SizedBox(height: 16),
            _buildProfileSection(
              title: 'Professional Details',
              children: [
                _buildProfileDetail('Designation', userData['designation']),
                _buildProfileDetail('About', userData['about']),
                _buildProfileDetail('Skills', userData['skills']),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.deepPurple, // Theme color
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileDetail(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.deepPurple.shade700, // Slightly darker theme color
            ),
          ),
          SizedBox(height: 4),
          Text(
            value ?? 'Not provided',
            style: TextStyle(fontSize: 16),
          ),
          Divider(color: Colors.grey.shade300), // Light divider
        ],
      ),
    );
  }
}