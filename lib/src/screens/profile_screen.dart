import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _user;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;

  void initState() {
    _user = FirebaseAuth.instance.currentUser!;
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .snapshots();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Loading indicator while data is being fetched
          }

          if (!snapshot.hasData) {
            return const Text('Error fetching data'); // Handle error case
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final username = userData['username'] ?? 'User';

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  "Hello $username",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 19),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamed(context, "/login");
                },
                child: Container(
                  height: 45,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      "Sign out",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
