import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'Screens/Welcome/welcome_screen.dart';
import 'constants.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:e_learning_platform/Screens/Home/home_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if(kIsWeb)
  {
    await Firebase.initializeApp(options: FirebaseOptions(
        apiKey: "AIzaSyDXNM3sLFpKzajkm7TWaUA1smV5qcJdVgY",
        authDomain: "e-learning-platform-1a0eb.firebaseapp.com",
        projectId: "e-learning-platform-1a0eb",
        storageBucket: "e-learning-platform-1a0eb.firebasestorage.app",
        messagingSenderId: "789899806730",
        appId: "1:789899806730:web:9111831cbed415c64e37f3"
    ));
  }
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auth',
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            foregroundColor: Colors.white,
            backgroundColor: kPrimaryColor,
            shape: const StadiumBorder(),
            maximumSize: const Size(double.infinity, 56),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: kPrimaryLightColor,
          iconColor: kPrimaryColor,
          prefixIconColor: kPrimaryColor,
          contentPadding:
          EdgeInsets.symmetric(horizontal: defaultPadding, vertical: defaultPadding),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const SplashScreen(), // Set SplashScreen as the initial screen
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) =>  HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/splash.json', // Ensure the correct path
          width: 300, // Adjust size as needed
          fit: BoxFit.cover,
          repeat: true, // Animation will loop
          animate: true, // Auto-play animation
        ),
      ),
    );
  }
}
