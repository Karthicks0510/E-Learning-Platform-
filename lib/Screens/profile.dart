import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _profileImageBytes;
  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _mobileNumberController = TextEditingController();
  TextEditingController _aboutController = TextEditingController();
  TextEditingController _skillsController = TextEditingController();
  TextEditingController _projectsController = TextEditingController();
  String? _currentOccupation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _saveProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        Map<String, dynamic> profileData = {
          'fullName': _fullNameController.text,
          'mobileNumber': _mobileNumberController.text,
          'occupation': _currentOccupation,
          'about': _aboutController.text,
          'skills': _skillsController.text,
          'projects': _projectsController.text,
        };

        await _firestore.collection('users').doc(user.uid).update(profileData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in.')),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double maxWidth = screenWidth > 600 ? 600 : screenWidth - 32;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _profileImageBytes != null
                            ? MemoryImage(_profileImageBytes!)
                            : AssetImage('assets/default_profile.png') as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                            child: Icon(Icons.edit, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(labelText: 'Full Name'),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _mobileNumberController,
                  decoration: InputDecoration(labelText: 'Mobile Number (+Country Code)'),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _currentOccupation,
                  decoration: InputDecoration(labelText: 'Current Occupation'),
                  items: <String>[
                    'Student',
                    'Teacher',
                    'Professional',
                    'Researcher',
                    'Freelancer',
                    'Entrepreneur',
                    'Other'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _currentOccupation = newValue;
                    });
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _aboutController,
                  decoration: InputDecoration(labelText: 'About'),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _skillsController,
                  decoration: InputDecoration(labelText: 'Skills'),
                  maxLines: 2,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _projectsController,
                  decoration: InputDecoration(labelText: 'Projects'),
                  maxLines: 3,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}