import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../home_screen.dart';
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

    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('users').get();
    List<Map<String, dynamic>> results = snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    }).where((user) {
      String fullName = user['fullName'].toString().toLowerCase();
      return fullName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomeScreen())); // Navigate to HomeScreen
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => HomeScreen())); // Navigate to HomeScreen
            },
          ),
          title: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: searchUsers,
                decoration: InputDecoration(
                  hintText: 'Search Users...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          backgroundColor: Colors.deepPurple,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth > 600 ? 300.0 : 200.0;
              return Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _searchResults.map((user) {
                  return SizedBox(
                    width: cardWidth,
                    child: FadeInLeft(
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Icon(Icons.person, color: Colors.deepPurple),
                          ),
                          title: Text(user['fullName'],
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(user['occupation'] ?? 'No occupation'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserProfileScreen(userId: user['id']),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  final String userId;

  UserProfileScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: FutureBuilder<DocumentSnapshot>(
          future:
          FirebaseFirestore.instance.collection('users').doc(userId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            return FadeIn(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Icon(Icons.person,
                                size: 50, color: Colors.deepPurple),
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Text(userData['fullName'],
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(height: 20),
                        Text(
                            'Occupation: ${userData['occupation'] ?? "Not specified"}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                        SizedBox(height: 10),
                        Text('Email: ${userData['email'] ?? "Not provided"}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                        SizedBox(height: 10),
                        Text('Skills: ${userData['skills'] ?? "Not provided"}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                        SizedBox(height: 10),
                        Text(
                            'Projects: ${userData['projects'] ?? "Not provided"}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                        SizedBox(height: 10),
                        Text('About: ${userData['about'] ?? "Not provided"}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

