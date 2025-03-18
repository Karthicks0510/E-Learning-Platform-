import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
  List<String> preferredLanguages = [];
  String subjectCategory = '';
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  List<String> languageOptions = [
    'English', 'Tamil', 'Mandarin Chinese', 'Hindi', 'Spanish',
    'French', 'Arabic', 'Bengali', 'Russian', 'Portuguese',
    'Urdu', 'Indonesian', 'German', 'Japanese', 'Marathi',
    'Telugu', 'Turkish', 'Yue Chinese (Cantonese)', 'Vietnamese', 'Italian'
  ];

  String convertToTitleCase(String text) {
    if (text.isEmpty) return '';
    List<String> words = text.split(' ');
    return words.map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '').join(' ');
  }

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
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                onChanged: (value) => title = value,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                onChanged: (value) => description = value,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Subject Category'),
                validator: (value) => value!.isEmpty ? 'Please enter a subject category' : null,
                onChanged: (value) => subjectCategory = value,
              ),
              SizedBox(height: 10),
              Text('Preferred Languages'),
              Wrap(
                spacing: 8.0,
                children: languageOptions.map((language) => ChoiceChip(
                  label: Text(language),
                  selected: preferredLanguages.contains(language),
                  onSelected: (isSelected) {
                    setState(() {
                      if (isSelected) {
                        preferredLanguages.add(language);
                      } else {
                        preferredLanguages.remove(language);
                      }
                    });
                  },
                )).toList(),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    type: FileType.any,
                  );

                  if (result != null) {
                    setState(() {
                      attachments = result.paths.map((path) => File(path!)).toList();
                    });
                  }
                },
                child: Text('Add Attachments'),
              ),
              if (attachments.isNotEmpty)
                Column(
                  children: attachments.map((file) => Text(path.basename(file.path))).toList(),
                ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Rewards'),
                      onChanged: (value) => rewards = value,
                    ),
                  ),
                  DropdownButton<String>(
                    value: selectedCurrency,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCurrency = newValue!;
                      });
                    },
                    items: ['USD', 'EUR', 'GBP', 'INR'].map<DropdownMenuItem<String>>((String value) {
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text('Post'),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User is not logged in. Please log in.')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance.collection('posts').add({
                  'title': convertToTitleCase(title),
                  'description': description,
                  'rewards': rewards,
                  'currency': selectedCurrency,
                  'uid': user.uid,
                  'postId': Uuid().v4(),
                  'attachments': [],
                  'preferredLanguages': preferredLanguages,
                  'subjectCategory': convertToTitleCase(subjectCategory),
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Post saved successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('An error occurred: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
