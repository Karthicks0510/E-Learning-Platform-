import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool isMobile;
  final VoidCallback? onMenuPressed;

  CustomAppBar({required this.isMobile, this.onMenuPressed});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(75);
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _isHoveringProfile = false;
  bool _isHoveringNotification = false;
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double searchBarWidth = screenWidth > 1200
        ? 500.0 // Added .0 to make it a double
        : screenWidth > 600
        ? 400.0 // Added .0 to make it a double
        : screenWidth * 0.6;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade800, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.isMobile
            ? IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: widget.onMenuPressed,
        )
            : null,
        title: Center(
          child: Container(
            width: searchBarWidth,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.15),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        actions: [
          _buildIconButton(Icons.notifications, _isHoveringNotification, () {}),
          SizedBox(width: 10),
          _buildIconButton(Icons.account_circle, _isHoveringProfile, () {}),
          SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, bool isHovering, VoidCallback onPressed) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          boxShadow: isHovering
              ? [
            BoxShadow(
              color: Colors.white.withOpacity(0.6),
              blurRadius: 10,
            ),
          ]
              : [],
        ),
        child: IconButton(
          icon: Icon(icon, size: 30, color: Colors.white),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

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