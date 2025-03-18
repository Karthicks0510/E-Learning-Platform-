// home_screen.dart
import 'package:e_learning_platform/Screens/Home/Components/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'Components/appbar.dart';
import 'all_posts.dart';
import 'package:animate_do/animate_do.dart';
import 'components/offer_of_the_day_dialog.dart';
import 'components/create_post_dialog.dart'; // Import the new file

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _fabScale = 1.0;

  @override
  void initState() {
    super.initState();
    _showOfferOfTheDayDialog();
  }

  Future<void> _showOfferOfTheDayDialog() async {
    await Future.delayed(Duration.zero);
    showDialog(
      context: context,
      builder: (BuildContext context) => OfferOfTheDayDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth <= 600;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(75),
        child: Builder(
          builder: (scaffoldContext) => CustomAppBar(
            isMobile: isMobile,
            onMenuPressed: isMobile
                ? () => Scaffold.of(scaffoldContext).openDrawer()
                : null,
          ),
        ),
      ),
      body: Row(
        children: [
          if (!isMobile)
            SizedBox(
              width: 250,
              child: CustomDrawer(),
            ),
          Expanded(
            child: FadeIn(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: AllPosts(),
              ),
            ),
          ),
        ],
      ),
      drawer: isMobile ? CustomDrawer() : null,
      floatingActionButton: AnimatedScale(
        scale: _fabScale,
        duration: Duration(milliseconds: 200),
        child: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              _fabScale = 0.9;
            });
            Future.delayed(Duration(milliseconds: 200), () {
              setState(() {
                _fabScale = 1.0;
              });
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) => CreatePostDialog(), // Use the imported dialog
              );
            });
          },
          icon: Icon(Icons.add),
          label: Text('New Post'),
          tooltip: 'Create a new post',
        ),
      ),
    );
  }
}