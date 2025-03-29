import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  UserProfileScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('User Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: SweepGradient(
              colors: [
                Colors.deepPurple.shade200,
                Colors.purple.shade300,
                Colors.deepPurple.shade400,
                Colors.purple.shade500,
                Colors.deepPurple.shade200,
              ],
              center: Alignment.center,
              startAngle: 0,
              endAngle: 3.14 * 2,
            ),
          ),
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Colors.deepPurple));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text('User not found', style: TextStyle(color: Colors.deepPurple)));
              }

              var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

              return FadeInUp(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 600),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              image: userData['banner_url'] != null
                                  ? DecorationImage(
                                image: NetworkImage(userData['banner_url']),
                                fit: BoxFit.cover,
                              )
                                  : BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.deepPurple, Colors.purple],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ).image,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 80.0),
                              child: Center(
                                child: CircleAvatar(
                                  radius: 70,
                                  backgroundImage: userData['profile_url'] != null
                                      ? NetworkImage(userData['profile_url'])
                                      : null,
                                  backgroundColor: Colors.white,
                                  child: userData['profile_url'] == null
                                      ? Icon(Icons.person, size: 70, color: Colors.deepPurple)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text(userData['name'] ?? 'No Name',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 26, fontWeight: FontWeight.bold)),
                                    ),
                                    SizedBox(height: 20),
                                    _buildProfileDetail(Icons.person, 'Username', userData['username'] ?? 'Unknown'),
                                    _buildProfileDetail(Icons.phone, 'Mobile', userData['mobile']?.toString() ?? 'Not specified'),
                                    _buildProfileDetail(Icons.work, 'Designation', userData['designation'] ?? 'Not provided'),
                                    _buildProfileDetail(Icons.email, 'Email', userData['email'] ?? 'Not provided'),
                                    _buildProfileDetail(Icons.info, 'About', userData['about'] ?? 'Not specified'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetail(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$title:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                Text(value, style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}