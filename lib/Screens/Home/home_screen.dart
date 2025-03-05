import 'package:flutter/material.dart';
import 'Components/appbar.dart'; // Import Custom AppBar & Drawer

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth <= 600;

    return Scaffold(
      body: Builder(
        builder: (context) => Row( // Use Row as the main layout
          children: [
            if (!isMobile)
              SizedBox(
                width: 250, // Fixed width for drawer on large screens
                child: CustomDrawer(),
              ),
            Expanded(
              child: Column( // Use Column for the rest of the content
                children: [
                  CustomAppBar(
                    isMobile: isMobile,
                    onMenuPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Welcome to HomeScreen!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: isMobile ? CustomDrawer() : null,
    );
  }
}