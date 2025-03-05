import 'package:flutter/material.dart';
import 'Components/appbar.dart';
import '../create_post.dart'; // Import CreatePostDialog

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth <= 600;

    return Scaffold(
      body: Builder(
        builder: (context) => Row(
          children: [
            if (!isMobile)
              SizedBox(
                width: 250,
                child: CustomDrawer(),
              ),
            Expanded(
              child: Column(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) => CreatePostDialog(),
          );
        },
        icon: Icon(Icons.add),
        label: Text('New Post'),
        tooltip: 'Create a new post',
      ),
    );
  }
}