import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'my_posts.dart';
import 'search_user.dart';
import 'chat_screen.dart';

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
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc.get('username');
            _userEmail = user.email;
          });
        } else {
          setState(() {
            _userName = "User Not Found";
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        children: [
          FadeInDown(
            child: UserAccountsDrawerHeader(
              accountName: Text(
                _userName ?? "Guest",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                _userEmail ?? "",
                style: TextStyle(fontSize: 14),
              ),
              currentAccountPicture: BounceInDown(
                child: CircleAvatar(
                  backgroundImage: AssetImage("assets/profile.jpg"),
                  radius: 30,
                ),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade800, Colors.purple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          ..._buildDrawerItems(context),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems(BuildContext context) {
    List<DrawerItem> items = [
      DrawerItem(Icons.home, "Home", context),
      DrawerItem(Icons.chat, "Chat", context, ChatScreen(currentUserId: _auth.currentUser?.uid ?? '')), // Pass UID
      DrawerItem(Icons.info, "About Us", context),
      DrawerItem(Icons.contact_mail, "Contact Us", context),
      DrawerItem(Icons.post_add, "My Posts", context, MyPostsScreen()),
      DrawerItem(Icons.search, "Search User", context, SearchUser()),
      DrawerItem(Icons.settings, "Settings", context),
      DrawerItem(Icons.logout, "Logout", context),
    ];

    return items
        .asMap()
        .entries
        .map((entry) => _buildAnimatedDrawerItem(entry.key, entry.value))
        .toList();
  }

  Widget _buildAnimatedDrawerItem(int index, DrawerItem item) {
    bool isHovering = false;

    return FadeInLeft(
      delay: Duration(milliseconds: 50 * index),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return InkWell(
            onTap: () {
              Navigator.pop(context);
              if (item.navigateTo != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => item.navigateTo!,
                  ),
                );
              }
            },
            onHover: (hovered) {
              setState(() {
                isHovering = hovered;
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              transform: isHovering ? Matrix4.identity().scaled(1.05) : Matrix4.identity(),
              child: ListTile(
                leading: Icon(item.icon, color: Colors.deepPurple.shade800),
                title: Text(
                  item.title,
                  style: TextStyle(color: isHovering ? Colors.white : null),
                ),
                tileColor: isHovering ? Colors.deepPurple.shade400 : Colors.transparent,
              ),
            ),
          );
        },
      ),
    );
  }
}

class DrawerItem {
  final IconData icon;
  final String title;
  final BuildContext context;
  final Widget? navigateTo;

  DrawerItem(this.icon, this.title, this.context, [this.navigateTo]);
}
