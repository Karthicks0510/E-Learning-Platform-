import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

class CreatePostDialog extends StatefulWidget {
  @override
  _CreatePostDialogState createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  String title = '';
  String description = '';
  List<PlatformFile> attachments = [];
  String rewards = '';
  String selectedCurrency = 'USD';
  List<String> preferredLanguages = [];
  String subjectCategory = '';
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  bool _isUploading = false;

  List<String> languageOptions = [
    'English',
    'Tamil',
    'Hindi',
    'Spanish',
    'French'
  ];

  String convertToTitleCase(String text) {
    if (text.isEmpty) return '';
    List<String> words = text.split(' ');
    return words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Future<List<String>> _uploadAttachments(String postId) async {
    List<String> attachmentUrls = [];
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User is not logged in. Please log in.')),
        );
      }
      return [];
    }

    for (var file in attachments) {
      try {
        final filePath = 'users/${user.uid}/posts/${file.name}';
        await supabase.storage.from('post-files').uploadBinary(
          filePath,
          file.bytes!,
          fileOptions: FileOptions(cacheControl: '3600', upsert: false),
        );
        final publicUrl =
        supabase.storage.from('post-files').getPublicUrl(filePath);
        attachmentUrls.add(publicUrl);
      } catch (e) {
        print('Error uploading attachment: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading attachment: ${file.name}')),
          );
        }
      }
    }
    return attachmentUrls;
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
                validator: (value) =>
                value!.isEmpty ? 'Please enter a title' : null,
                onChanged: (value) => title = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a description' : null,
                onChanged: (value) => description = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Subject Category'),
                onChanged: (value) => subjectCategory = value,
              ),
              Text('Preferred Languages'),
              Wrap(
                spacing: 8.0,
                children: languageOptions
                    .map((language) => ChoiceChip(
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
                ))
                    .toList(),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result =
                  await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    type: FileType.any,
                    withData: true,
                  );

                  if (result != null) {
                    setState(() {
                      attachments = result.files;
                    });
                  }
                },
                child: Text('Add Attachments'),
              ),
              if (attachments.isNotEmpty)
                Column(
                  children:
                  attachments.map((file) => Text(file.name)).toList(),
                ),
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
                    items: ['USD', 'EUR', 'GBP', 'INR']
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: _isUploading ? CircularProgressIndicator() : Text('Post'),
          onPressed: _isUploading
              ? null
              : () async {
            if (_formKey.currentState!.validate()) {
              if (!mounted) return; // Check before setState
              setState(() => _isUploading = true);

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'User is not logged in. Please log in.')),
                  );
                }
                setState(() => _isUploading = false);
                return;
              }

              try {
                final postId = Uuid().v4();
                List<String> attachmentUrls =
                await _uploadAttachments(postId);

                await FirebaseFirestore.instance
                    .collection('posts')
                    .add({
                  'title': convertToTitleCase(title),
                  'description': description,
                  'rewards': rewards,
                  'currency': selectedCurrency,
                  'uid': user.uid,
                  'postId': postId,
                  'attachments': attachmentUrls,
                  'preferredLanguages': preferredLanguages,
                  'subjectCategory': convertToTitleCase(subjectCategory),
                });

                setState(() => _isUploading = false);

                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Post saved successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                }
                setState(() => _isUploading = false);
              }
            }
          },
        ),
      ],
    );
  }
}