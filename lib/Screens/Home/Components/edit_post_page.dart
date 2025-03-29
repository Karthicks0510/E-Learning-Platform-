import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_io/io.dart' if (dart.library.html) 'package:universal_io/io.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';

class EditPostPage extends StatefulWidget {
  final String postId;

  EditPostPage({required this.postId});

  @override
  _EditPostPageState createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rewardsController = TextEditingController();
  final _currencyController = TextEditingController();
  final _preferredLanguagesController = TextEditingController();

  File? _image;
  String? _imageUrl;
  bool _isLoading = false;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  Future<void> _fetchPostData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      print('Fetching post data for postId: ${widget.postId}');
      DocumentSnapshot snapshot =
      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _rewardsController.text = data['rewards']?.toString() ?? '';
        _currencyController.text = data['currency'] ?? '';
        _preferredLanguagesController.text =
            (data['preferredLanguages'] as List?)?.join(', ') ?? '';
        _imageUrl = data['imageUrl'];
        print('Post data fetched successfully.');
      } else {
        print('Post does not exist.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post not found.')));
      }
    } catch (e) {
      print('Error loading post data: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load post data.')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          print('Image picked: ${_image!.path}');
        });
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image.')));
    }
  }

  Future<String?> _uploadPostImage(File imageFile, String postId) async {
    try {
      print('Uploading image: ${imageFile.path}');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in.');
        return null;
      }

      final uid = user.uid;
      final fileName = path.basename(imageFile.path);
      final fileExt = path.extension(imageFile.path);
      final storagePath = 'users/$uid/posts/$postId/$fileName$fileExt';

      print('Storage path: $storagePath');

      Uint8List imageBytes;
      try {
        imageBytes = await imageFile.readAsBytes();
        print('Image bytes read successfully.');
      } catch (e) {
        print('Error reading image bytes: $e');
        return null;
      }

      await supabase.storage.from('post-files').uploadBinary(
        storagePath,
        imageBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final imageUrl = supabase.storage.from('post-files').getPublicUrl(storagePath);
      print('Image URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _updatePost() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        String? newImageUrl = _imageUrl;

        if (_image != null) {
          newImageUrl = await _uploadPostImage(_image!, widget.postId);
          if (newImageUrl == null) {
            if(context.mounted){
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed.')));
              setState(() {_isLoading = false;});
              return;
            }
          }
        }

        List<String> languages = _preferredLanguagesController.text.split(',').map((e) => e.trim()).toList();

        await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'rewards': double.tryParse(_rewardsController.text) ?? 0.0,
          'currency': _currencyController.text,
          'preferredLanguages': languages,
          'imageUrl': newImageUrl,
        });

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post updated successfully.')));
        }
      } catch (e, stackTrace) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update post: $e')));
          print('Error updating post: $e');
          print('StackTrace: $stackTrace');
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Edit Post', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.purple,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
        padding: const EdgeInsets.all(16.0),
    child: Center(
    child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: 600),
    child: Form(
    key: _formKey,
    child: ListView(
    children: [
    _buildTextField(
    controller: _titleController, label: 'Title', validator: _validateNotEmpty),
    SizedBox(height: 16),
    _buildTextField(
    controller: _descriptionController,
    label: 'Description',
    validator: _validateNotEmpty),
    SizedBox(height: 16),
    _buildTextField(
    controller: _rewardsController,
    label: 'Rewards',
    keyboardType: TextInputType.number,
    validator: _validateNotEmpty),
    SizedBox(height: 16),
    _buildTextField(
    controller: _currencyController,
    label: 'Currency',
    validator: _validateNotEmpty),
    SizedBox(height: 16),
    _buildTextField(
    controller: _preferredLanguagesController,
    label: 'Preferred Languages (comma separated)',
    validator: _validateNotEmpty),
    SizedBox(height: 24),
    ElevatedButton(
    onPressed: _pickImage,
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.purple, foregroundColor: Colors.white),
    child: Text('Pick Image'),
    ),
    if (_image != null)
    Padding(
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    child: ClipRRect(
    borderRadius: BorderRadius.circular(8.0),
    child: Image.network( // Use Image.network here
    _image!.path,
    headers: {'Cache-Control': 'no-cache'},
    errorBuilder: (context, error, stackTrace) {
    print('Image network error: $error');
    return Text('Failed to load image.');},
    ),
    ),
    ),
      if (_imageUrl != null && _imageUrl!.isNotEmpty && _image == null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              _imageUrl!,
              headers: {'Cache-Control': 'no-cache'},
              errorBuilder: (context, error, stackTrace) {
                print('Image network error: $error');
                return Text('Failed to load image.');
              },
            ),
          ),
        ),
      SizedBox(height: 32),
      ElevatedButton(
        onPressed: _updatePost,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple, foregroundColor: Colors.white),
        child: Text('Update Post'),
      ),
    ],
    ),
    ),
    ),
    ),
        ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  String? _validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter $value';
    }
    return null;
  }
}