import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

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
    'French',
    'German',
    'Japanese',
    'Chinese',
    'Arabic',
    'Russian',
  ];

  String convertToTitleCase(String text) {
    if (text.isEmpty) return '';
    List<String> words = text.split(' ');
    return words
        .where((word) => word.isNotEmpty)
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
        final filePath = 'users/${user.uid}/posts/$postId/${file.name}';
        await supabase.storage.from('post-files').uploadBinary(
          filePath,
          file.bytes!,
          fileOptions: FileOptions(cacheControl: '3600', upsert: false),
        );
        final publicUrl = supabase.storage.from('post-files').getPublicUrl(filePath);
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
        title: Text('Create Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                  onChanged: (value) => title = value,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                  onChanged: (value) => description = value,
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Subject Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) => subjectCategory = value,
                ),
                SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Preferred Languages',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: languageOptions.map((language) {
                      return FilterChip(
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
                        checkmarkColor: Colors.white,
                        selectedColor: Colors.blue,
                        labelStyle: TextStyle(color: preferredLanguages.contains(language) ? Colors.white : Colors.black),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
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
                  icon: Icon(Icons.attach_file),
                  label: Text('Add Attachments'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 8),
                if (attachments.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: attachments.map((file) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(file.name, style: TextStyle(fontStyle: FontStyle.italic)),
                    )).toList(),
                  ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Rewards',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (value) => rewards = value,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a reward amount';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedCurrency,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCurrency = newValue!;
                        });
                      },
                      items: ['USD', 'EUR', 'GBP', 'INR','YEN','Franc','AUD','CAD'].map<DropdownMenuItem<String>>((String value) {
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
    child: Text('Cancel', style: TextStyle(color: Colors.grey)),
    onPressed: () => Navigator.of(context).pop(),
    ),
    ElevatedButton(
    child: _isUploading ? CircularProgressIndicator() : Text('Post', style: TextStyle(color: Colors.white)),
    onPressed: _isUploading
    ? null
        : () async {
    if (_formKey.currentState!.validate()) {
    if (!mounted) return;
    setState(() => _isUploading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
    if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('User is not logged in. Please log in.')),
    );
    }
    setState(() => _isUploading = false);
    return;
    }

    try {
    final postId = Uuid().v4();
    List<String> attachmentUrls = await _uploadAttachments(postId);
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .set({
      'title': convertToTitleCase(title),
      'description': description,
      'rewards': int.parse(rewards),
      'currency': selectedCurrency,
      'uid': user.uid,
      'postId': postId,
      'attachments': attachmentUrls,
      'preferredLanguages': preferredLanguages,
      'subjectCategory': convertToTitleCase(subjectCategory),
      'timestamp': FieldValue.serverTimestamp(),
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
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
        ],
    );
  }
}