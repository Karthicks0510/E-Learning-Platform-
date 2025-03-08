import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_posts.dart'; // Import the MyPostsScreen

class CustomDrawer extends StatefulWidget {
  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? _userName;
  String? _userEmail;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            _userName = userDoc.get('username');
            _userEmail = user.email;
          });
        } else {
          print("User document not found.");
          setState(() {
            _userName = "User Not found";
            _userEmail = "";
          });
        }
      } catch (e) {
        print("Error loading user data: $e");
        setState(() {
          _userName = "Error Loading";
          _userEmail = "";
        });
      }
    } else {
      setState(() {
        _userName = "Guest";
        _userEmail = "";
      });
      print("User not logged in.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_userName ?? "Guest"),
            accountEmail: Text(_userEmail ?? ""),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage("assets/profile.jpg"),
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade800,
            ),
          ),
          _buildDrawerItem(Icons.home, "Home", context),
          _buildDrawerItem(Icons.info, "About Us", context),
          _buildDrawerItem(Icons.contact_mail, "Contact Us", context),
          _buildDrawerItem(Icons.post_add, "My Posts", context, MyPostsScreen()), // Pass MyPostsScreen
          Divider(),
          _buildDrawerItem(Icons.settings, "Settings", context),
          _buildDrawerItem(Icons.logout, "Logout", context),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, BuildContext context, [Widget? navigateTo]) { //added optional widget parameter
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple.shade800),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (navigateTo != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => navigateTo)); // navigate if widget is passed.
        }
      },
    );
  }
}