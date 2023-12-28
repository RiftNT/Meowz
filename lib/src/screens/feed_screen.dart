import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Cat {
  final String id;
  final String url;

  Cat({required this.id, required this.url});

  factory Cat.fromJson(Map<String, dynamic> json) {
    return Cat(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<List<Cat>> _cats;
  AppinioSwiperController _swiperController = AppinioSwiperController();
  int _currentIndex = 0;

  @override
  void initState() {
    _cats = _fetchCats();
    super.initState();
  }

  Future<List<Cat>> _fetchCats() async {
    final response = await http.get(Uri.parse(
        'https://api.thecatapi.com/v1/images/search?has_breeds=1&limit=10&api_key=live_ww8GBeUHkAu51IVO2DmnEPwoPj8hOPVoetILTJHlSWIvWYx8H1r1W8ZJvtkLAwZR'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Cat>.from(data.map((catData) => Cat.fromJson(catData)));
    } else {
      throw Exception('Failed to load cats: ${response.statusCode}');
    }
  }

  Future<void> addToFavorites(String catId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      final userId = user.uid;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(catId)
          .set({
            'timestamp': FieldValue.serverTimestamp(),
          });
    } else {
      print("No user is currently signed in.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _cats,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData) {
          List<Cat> cats = snapshot.data as List<Cat>;

          return Scaffold(
            body: SizedBox.expand(
              child: AppinioSwiper(
                backgroundCardCount: 3,
                swipeOptions: const SwipeOptions.symmetric(
                  horizontal: true,
                  vertical: false,
                ),
                maxAngle: 0,
                controller: _swiperController,
                onSwipeEnd: _swipeEnd,
                onEnd: _onEnd,
                cardCount: cats.length,
                cardBuilder: (BuildContext context, int index) {
                  return Card(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            cats[index].url,
                            fit: BoxFit.cover,
                            height: double.infinity,
                            width: double.infinity,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: Icon(Icons.cancel, size: 80, color: Colors.red),
                                onPressed: () {
                                  _swiperController.swipeLeft();
                                  addToFavorites(cats[_currentIndex].id);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.check_circle, size: 80, color: Colors.green),
                                onPressed: () {
                                  _swiperController.swipeRight();
                                  addToFavorites(cats[_currentIndex].id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          return const Center(
            child: Text("No Data"),
          );
        }
      },
    );
  }

  void _swipeEnd(int previousIndex, int targetIndex, SwiperActivity activity) {
    if (activity is Swipe) {
      setState(() {
        _currentIndex = targetIndex;
      });
    }
  }

  void _onEnd() {
    _cats = _fetchCats();
  }
}
