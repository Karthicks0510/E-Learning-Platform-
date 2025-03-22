import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuthAlias;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:animate_do/animate_do.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _profileImageBytes;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _aboutController = TextEditingController();
  TextEditingController _skillsController = TextEditingController();
  TextEditingController _designationController = TextEditingController();
  TextEditingController _mobileController = TextEditingController();
  String? _email;
  List<String> _languages = [];
  String? _profileImageUrl;

  final FirebaseAuthAlias.FirebaseAuth _auth = FirebaseAuthAlias.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    FirebaseAuthAlias.User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot =
        await _firestore.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _aboutController.text = data['about'] ?? '';
            _skillsController.text = data['skills'] ?? '';
            _designationController.text = data['designation'] ?? '';
            _mobileController.text = data['mobile'] ?? '';
            _email = user.email;
            _languages = List<String>.from(data['languages'] ?? []);
            _profileImageUrl = data['profile_url'];
          });
        }
      } catch (e) {
        print('Error loading profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile.')),
        );
      }
    }
  }

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
    setState(() {
      _isLoading = true;
    });

    try {
      FirebaseAuthAlias.User? user = _auth.currentUser;
      if (user != null) {
        Map<String, dynamic> profileData = {
          'name': _nameController.text,
          'about': _aboutController.text,
          'skills': _skillsController.text,
          'designation': _designationController.text,
          'mobile': _mobileController.text,
          'languages': _languages,
        };

        if (_profileImageBytes != null) {
          final fileName = path.basename('profile_image.jpg');
          final filePath = 'users/${user.uid}/profile/$fileName';

          try {
            await _supabase.storage.from('post-files').uploadBinary(
              filePath,
              _profileImageBytes!,
              fileOptions: FileOptions(cacheControl: '3600', upsert: false),
            );

            _profileImageUrl = _supabase.storage.from('post-files').getPublicUrl(filePath);
            profileData['profile_url'] = _profileImageUrl;
          } catch (supabaseError) {
            print('Supabase upload error: $supabaseError');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Supabase upload failed.')),
            );
            return;
          }
        }

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(profileData, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        setState(() {
          _isEditing = false;
        });
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: FadeIn(
        child: TextFormField(
          controller: controller,
          enabled: _isEditing,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            filled: true,
            fillColor: _isEditing ? Colors.white : Colors.grey[200],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageChips() {
    return Wrap(
      spacing: 8.0,
      children: _languages.map((lang) {
        return Chip(
          label: Text(lang),
          deleteIcon: Icon(Icons.close, color: Colors.red),
          onDeleted: _isEditing
              ? () {
            setState(() {
              _languages.remove(lang);
            });
          }
              : null,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 600;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.purple,
            title: Text('Profile'),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                onPressed: () {
                  setState(() {
                    if (_isEditing) {
                      _saveProfile();
                    }
                    _isEditing = !_isEditing;
                  });
                },
              ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                width: isLargeScreen ? 600 : double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : _profileImageBytes != null
                                ? MemoryImage(_profileImageBytes!)
                                : null,
                            child: _profileImageUrl == null &&
                                _profileImageBytes == null
                                ? Icon(Icons.person,
                                size: 80, color: Colors.grey)
                                : null,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                icon: Icon(Icons.camera_alt),
                                onPressed: _pickImage,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildTextField(_nameController, 'Name'),
                    _buildTextField(_aboutController, 'About'),
                    _buildTextField(_skillsController, 'Skills'),
                    _buildTextField(_designationController, 'Designation'),
                    _buildTextField(_mobileController, 'Mobile'),
                    Text('Email: $_email', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 10),
                    Text('Languages:', style: TextStyle(fontSize: 18)),
                    _buildLanguageChips(),
                    if (_isEditing)
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              String newLanguage = '';
                              return AlertDialog(
                                title: Text('Add Language'),
                                content: TextField(
                                  onChanged: (value) => newLanguage = value,
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _languages.add(newLanguage);
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Text('Add'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Text('Add Language'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}