import 'package:flutter/material.dart';
import 'Components/appbar.dart';
import '../create_post.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth <= 600;

    return Scaffold(
      body: Builder(
        builder: (scaffoldContext) {
          return Row(
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
                      onMenuPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
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
          );
        },
      ),
      drawer: isMobile ? CustomDrawer() : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: Navigator.of(context).overlay!.context, // Use overlay context
            builder: (BuildContext dialogContext) => CreatePostDialog(),
          );
        },
        icon: Icon(Icons.add),
        label: Text('New Post'),
        tooltip: 'Create a new post',
      ),
    );
  }
}