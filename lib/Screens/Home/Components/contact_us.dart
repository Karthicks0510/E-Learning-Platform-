// contact_us.dart
import 'package:e_learning_platform/Screens/Home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:animate_do/animate_do.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class ContactUsPage extends StatefulWidget {
  ContactUsPage({Key? key}) : super(key: key);

  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  File? _selectedFile;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  bool _isSending = false;

  Future<void> _selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          _selectedFileBytes = result.files.single.bytes;
          _selectedFileName = result.files.single.name;
          _selectedFile = null;
        } else {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = path.basename(_selectedFile!.path);
          _selectedFileBytes = null;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No file selected.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[600],
        ),
      );
    }
  }

  Future<void> _sendEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSending = true;
      });

      final String apiKey = dotenv.env['BREVO_API_KEY']??''; // Replace with your Brevo API key
      final String apiUrl = dotenv.env["BREVO_URL"]??'';
      final String fromEmail = dotenv.env['FROM_EMAIL']??''; // Replace with your from email
      final String fromName = 'SkillSphere Contact Form';
      final String toEmail = dotenv.env['ADMIN_EMAIL']??''; // Replace with the admin email

      try {
        String attachmentContent = '';
        String attachmentName = '';

        if (_selectedFileBytes != null || _selectedFile != null) {
          List<int> bytes;
          if (_selectedFileBytes != null) {
            bytes = _selectedFileBytes!;
          } else {
            bytes = await _selectedFile!.readAsBytes();
          }

          attachmentContent = base64Encode(bytes);
          attachmentName = _selectedFileName ?? 'attachment';
        }

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'accept': 'application/json',
            'api-key': apiKey,
          },
          body: jsonEncode(<String, dynamic>{
            'sender': {'email': fromEmail, 'name': fromName},
            'to': [
              {'email': toEmail}
            ],
            'subject': 'Contact Form Submission: ${_subjectController.text}',
            'htmlContent': '<p><b>Name:</b> ${_nameController.text}</p>'
                '<p><b>Username:</b> ${_usernameController.text}</p>'
                '<p><b>Email:</b> ${_emailController.text}</p>'
                '<p><b>Phone:</b> ${_phoneController.text}</p>'
                '<p><b>Message:</b> ${_messageController.text}</p>',
            if (attachmentContent.isNotEmpty)
              'attachment': [
                {
                  'content': attachmentContent,
                  'name': attachmentName,
                }
              ]
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email sent successfully!', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          );
          _nameController.clear();
          _usernameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _subjectController.clear();
          _messageController.clear();
          setState(() {
            _selectedFile = null;
            _selectedFileBytes = null;
            _selectedFileName = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send email. Please try again.', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
          print('Brevo Response Status Code: ${response.statusCode}');
          print('Brevo Response Body: ${utf8.decode(response.bodyBytes)}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
        print('Error sending email: $e');
      } finally {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomeScreen())),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600,
              ),
              child: FadeInUp(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: ScrollConfiguration(behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                        child:SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                'Get in Touch',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              SizedBox(height: 20),
                              _buildTextField(
                                controller: _nameController,
                                labelText: 'Name',
                                validator: _requiredValidator,
                                prefixIcon: Icons.person_outline,
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _usernameController,
                                labelText: 'Username',
                                validator: _requiredValidator,
                                prefixIcon: Icons.account_circle_outlined,
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                labelText: 'Email',
                                validator: _emailValidator,
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _phoneController,
                                labelText: 'Phone Number',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _subjectController,
                                labelText: 'Subject',
                                validator: _requiredValidator,
                                prefixIcon: Icons.subject_outlined,
                              ),
                              SizedBox(height: 16),
                              _buildTextField(
                                controller: _messageController,
                                labelText: 'Message',
                                validator: _requiredValidator,
                                prefixIcon: Icons.message_outlined,
                                maxLines: 4,
                              ),
                              SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _selectFile,
                                icon: Icon(Icons.attach_file),
                                label: Text('Attach File'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              if (_selectedFileName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Attached: $_selectedFileName',
                                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
                                  ),
                                ),
                              SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _isSending ? null : _sendEmail,
                                icon: _isSending
                                    ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                                    : Icon(Icons.send),
                                label: Text(_isSending ? 'Sending...' : 'Send Message'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        )
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines = 1,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        alignLabelWithHint: maxLines != null && maxLines > 1,
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter this field';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }
}