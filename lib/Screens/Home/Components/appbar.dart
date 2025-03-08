import 'package:flutter/material.dart';
import '../../profile.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_results_page.dart'; // Import the SearchResultsPage file

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

  void _performSearch(BuildContext context) {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(query: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double searchBarWidth = screenWidth > 1200
        ? 500.0
        : screenWidth > 600
        ? 400.0
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
              color: Colors.white.withAlpha((0.15 * 255).round()),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withAlpha((0.3 * 255).round())),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withAlpha((0.15 * 255).round()),
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
                fillColor: Colors.white.withAlpha((0.15 * 255).round()),
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => _performSearch(context),
            ),
          ),
        ),
        actions: [
          _buildIconButton(Icons.notifications, _isHoveringNotification, () {}),
          SizedBox(width: 10),
          _buildIconButton(Icons.account_circle, _isHoveringProfile, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          }),
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
              color: Colors.white.withAlpha((0.6 * 255).round()),
              blurRadius: 10,
            ),
          ]
              : [],
        ),
        child: IconButton(
          icon: Icon(icon, size: 30, color: Colors.white),
          onPressed: icon == Icons.account_circle
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          }
              : onPressed,
        ),
      ),
    );
  }
}