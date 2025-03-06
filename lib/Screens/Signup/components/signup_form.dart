import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../components/already_have_an_account_acheck.dart';
import '../../../constants.dart';
import '../../Login/login_screen.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({Key? key}) : super(key: key);

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            cursorColor: kPrimaryColor,
            decoration: const InputDecoration(
              hintText: "Username",
              prefixIcon: Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.person),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your username";
              }
              return null;
            },
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            cursorColor: kPrimaryColor,
            decoration: const InputDecoration(
              hintText: "Your email",
              prefixIcon: Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.email),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your email";
              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return "Enter a valid email";
              }
              return null;
            },
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            cursorColor: kPrimaryColor,
            decoration: const InputDecoration(
              hintText: "Your password",
              prefixIcon: Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.lock),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your password";
              } else if (value.length < 6) {
                return "Password must be at least 6 characters";
              }
              return null;
            },
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            cursorColor: kPrimaryColor,
            decoration: const InputDecoration(
              hintText: "Confirm password",
              prefixIcon: Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.lock),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please confirm your password";
              } else if (value != _passwordController.text) {
                return "Passwords do not match";
              }
              return null;
            },
          ),
          const SizedBox(height: defaultPadding),
          Row(
            children: [
              Checkbox(
                value: _agreeToTerms,
                activeColor: kPrimaryColor,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value!;
                  });
                },
              ),
              const Text("I agree to the Terms & Conditions"),
            ],
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            width: screenWidth * 0.8,
            child: ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() && _agreeToTerms) {
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );

                    await _firestore.collection('users').doc(userCredential.user!.uid).set({
                      'uid': userCredential.user!.uid,
                      'username': _usernameController.text,
                      'email': _emailController.text,
                    });

                    setState(() {
                      _isLoading = false;
                    });
                    _showSuccessDialog(context);
                  } on FirebaseAuthException catch (e) {
                    setState(() {
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Signup unsuccessful: ${e.message}'), backgroundColor: Colors.red),
                    );
                  } catch (e) {
                    setState(() {
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('An unexpected error occurred.'), backgroundColor: Colors.red),
                    );
                  }
                } else if (!_agreeToTerms) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please accept Terms & Conditions")),
                  );
                }
              },
              child: _isLoading ? const CircularProgressIndicator() : Text("Sign Up".toUpperCase()),
            ),
          ),
          const SizedBox(height: defaultPadding),
          AlreadyHaveAnAccountCheck(
            login: false,
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text("Account created successfully!"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}