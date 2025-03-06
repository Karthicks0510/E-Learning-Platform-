import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreatePostDialog extends StatefulWidget {
  @override
  _CreatePostDialogState createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  List<File> _attachments = [];
  String? _selectedCurrency = 'USD';
  TextEditingController _rewardValueController = TextEditingController();

  Future<void> _pickFiles() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(); // For images
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _attachments.addAll(pickedFiles.map((pickedFile) => File(pickedFile.path)));
      });
    }

    // Add logic for picking PDF files if needed
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create a New Post'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickFiles,
                child: Text('Add Attachments'),
              ),
              if (_attachments.isNotEmpty)
                Column(
                  children: _attachments.map((file) => Text(file.path.split('/').last)).toList(),
                ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(labelText: 'Currency'),
                      items: <String>[
                        'USD',
                        'EUR',
                        'INR',
                        'JPY',
                        'CHF'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCurrency = newValue;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _rewardValueController,
                      decoration: InputDecoration(labelText: 'Value'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a value';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Process the post data here
              print('Title: ${_titleController.text}');
              print('Description: ${_descriptionController.text}');
              print('Attachments: $_attachments');
              print('Reward: $_selectedCurrency ${_rewardValueController.text}');
              Navigator.of(context).pop();
            }
          },
          child: Text('Post'),
        ),
      ],
    );
  }
}