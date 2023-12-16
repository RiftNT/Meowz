import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:meowz/src/screens/home_screen.dart';
import 'package:meowz/src/screens/login_screen.dart';
import 'package:meowz/src/screens/register_screen.dart';
import 'package:meowz/src/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meowz',
      home: FutureBuilder(
        future: Firebase.initializeApp(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            User? user = FirebaseAuth.instance.currentUser;
            return (user != null) ? const HomeScreen() : const SplashScreen(child: LoginScreen()); 
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
