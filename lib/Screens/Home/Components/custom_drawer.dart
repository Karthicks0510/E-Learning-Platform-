import 'package:flutter/material.dart';
class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text("John Doe"),
            accountEmail: Text("johndoe@example.com"),
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
          _buildDrawerItem(Icons.post_add, "My Posts", context),
          Divider(),
          _buildDrawerItem(Icons.settings, "Settings", context),
          _buildDrawerItem(Icons.logout, "Logout", context),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple.shade800),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}