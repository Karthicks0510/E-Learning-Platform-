/// home_screen.dart
import 'package:e_learning_platform/Screens/Home/Components/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'Components/appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'all_posts.dart';
import 'package:animate_do/animate_do.dart'; // Import animate_do

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _fabScale = 1.0;

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
            child: FadeIn( // Add FadeIn animation for AllPosts
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
                builder: (BuildContext dialogContext) => CreatePostDialog(),
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


class CreatePostDialog extends StatefulWidget {
  @override
  _CreatePostDialogState createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  String title = '';
  String description = '';
  List<File> attachments = [];
  String rewards = '';
  String selectedCurrency = 'USD';
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Post'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onChanged: (value) {
                  title = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onChanged: (value) {
                  description = value;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                  );

                  if (result != null) {
                    setState(() {
                      attachments = result.paths.map((path) => File(path!)).toList();
                    });
                  } else {}
                },
                child: Text('Add Attachments'),
              ),
              if (attachments.isNotEmpty)
                Column(
                  children: attachments.map((file) => Text(file.path.split('/').last)).toList(),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Rewards'),
                      onChanged: (value) {
                        rewards = value;
                      },
                    ),
                  ),
                  DropdownButton<String>(
                    value: selectedCurrency,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCurrency = newValue!;
                      });
                    },
                    items: <String>['USD', 'EUR', 'GBP', 'INR']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Post'),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('posts').add({
                    'title': title,
                    'description': description,
                    'rewards': rewards,
                    'currency': selectedCurrency,
                    'uid': user.uid,
                    'attachments': attachments.map((file) => file.path.split('/').last).toList(),
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Post saved successfully!')),
                  );
                } else {
                  print("User not logged in");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User not logged in.')),
                  );
                }
              } catch (e) {
                print('Error adding post: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving post. Please try again.')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}