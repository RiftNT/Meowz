import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meowz/src/models/cats_model.dart';
import 'package:meowz/src/screens/favorites_screen.dart';
import 'package:meowz/src/screens/feed_screen.dart';
import 'package:meowz/src/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late User _user;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;

  int pageIndex = 0;
  final List<Widget> _pages = [
    const FeedScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  @override
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

          return Scaffold(
            body: _pages[pageIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: pageIndex,
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: false,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: "Dashboard",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: "Favorites",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle_outlined),
                  label: "Profile",
                ),
              ],
              onTap: (index) {
                setState(() {
                  pageIndex = index;
                });
              },
            ),
          );
        },
      ),
    );
  }
}
