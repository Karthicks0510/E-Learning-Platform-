import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';

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

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot =
      await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _fullNameController.text = data['fullName'] ?? '';
          _mobileNumberController.text = data['mobileNumber'] ?? '';
          _currentOccupation = data['occupation'];
          _aboutController.text = data['about'] ?? '';
          _skillsController.text = data['skills'] ?? '';
          _projectsController.text = data['projects'] ?? '';

          if (data.containsKey('profileImage')) {
            try {
              List<int> imageList = (data['profileImage'] as List).cast<int>();
              _profileImageBytes = Uint8List.fromList(imageList);
            } catch (e) {
              print('Error loading profile image: $e');
            }
          }
        });
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

        if (_profileImageBytes != null) {
          profileData['profileImage'] = _profileImageBytes!.toList();
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
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int? maxLines, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white70
                : Colors.grey.shade400),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white30
                    : Colors.grey.shade700)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Colors.grey.shade400)),
        border: OutlineInputBorder(
            borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white30
                    : Colors.grey.shade700)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white12
            : Colors.grey.shade900.withOpacity(0.5),
      ),
      style: TextStyle(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Colors.grey.shade300),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _currentOccupation,
      decoration: InputDecoration(
        labelText: 'Designation',
        labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white70
                : Colors.grey.shade400),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white30
                    : Colors.grey.shade700)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Colors.grey.shade400)),
        border: OutlineInputBorder(
            borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white30
                    : Colors.grey.shade700)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white12
            : Colors.grey.shade900.withOpacity(0.5),
      ),
      style: TextStyle(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Colors.grey.shade300),
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
          child: Text(
            value,
            style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black87
                    : Colors.grey.shade300),
          ),
        );
      }).toList(),
      onChanged: _isEditing // Allow onChanged only in editing mode
          ? (String? newValue) {
        setState(() {
          _currentOccupation = newValue;
        });
      }
          : null,
      dropdownColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey.shade200
          : Colors.grey.shade800,
    );
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double maxWidth = screenWidth > 600 ? 600 : screenWidth - 32;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FadeInDown(
            child: Text('Profile',
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Colors.grey.shade300))),
        iconTheme: IconThemeData(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Colors.grey.shade300),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FadeIn(
            child: Image.asset(
              'assets/icons/default_profile.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).brightness == Brightness.light
                      ? Colors.deepPurple.withOpacity(0.8)
                      : Colors.grey.shade800.withOpacity(0.8),
                  Theme.of(context).brightness == Brightness.light
                      ? Colors.purple.withOpacity(0.6)
                      : Colors.grey.shade900.withOpacity(0.6),
                  Theme.of(context).brightness == Brightness.light
                      ? Colors.blue.withOpacity(0.5)
                      : Colors.grey.shade700.withOpacity(0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ZoomIn(
                      child: Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: _profileImageBytes != null
                                  ? MemoryImage(_profileImageBytes!)
                                  : AssetImage('assets/default_profile.png')
                              as ImageProvider,
                            ),
                            if (_isEditing)
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
                                    child: Icon(Icons.edit,
                                        color: Theme.of(context).brightness ==
                                            Brightness.light
                                            ? Colors.white
                                            : Colors.grey.shade300),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    FadeInLeft(
                        child: _buildTextField(_fullNameController, 'Full Name')),
                    SizedBox(height: 10),
                    FadeInLeft(
                        child: _buildTextField(
                            _mobileNumberController,
                            'Mobile Number (+Country Code)',
                            keyboardType: TextInputType.phone)),
                    SizedBox(height: 10),
                    FadeInLeft(child: _buildDropdown()),
                    SizedBox(height: 10),
                    FadeInLeft(
                        child: _buildTextField(
                            _aboutController, 'About',
                            maxLines: 3)),
                    SizedBox(height: 10),
                    FadeInLeft(
                        child: _buildTextField(
                            _skillsController, 'Skills',
                            maxLines: 2)),
                    SizedBox(height: 10),
                    FadeInLeft(
                        child: _buildTextField(
                            _projectsController, 'Projects',
                            maxLines: 3)),
                    SizedBox(height: 20),
                    if (_isEditing)
                      FadeInUp(
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text('Save Profile',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).brightness ==
                                      Brightness.light
                                      ? Colors.white
                                      : Colors.grey.shade300)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}