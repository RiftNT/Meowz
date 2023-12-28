import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Cat {
  final String id;
  final String url;
  final Map<String, dynamic> breed;

  Cat({required this.id, required this.url, required this.breed});

  factory Cat.fromJson(Map<String, dynamic> json) {
    return Cat(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      breed: (json['breeds'] as List).isNotEmpty ? json['breeds'][0] : {},
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
  late List<Cat> _catsList;
  bool _showDetails = false;

  @override
  void initState() {
    _cats = _fetchCats();
    super.initState();
  }

  Future<List<Cat>> _fetchCats() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.thecatapi.com/v1/images/search?has_breeds=1&limit=10&api_key=live_ww8GBeUHkAu51IVO2DmnEPwoPj8hOPVoetILTJHlSWIvWYx8H1r1W8ZJvtkLAwZR'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty && data[0].containsKey('breeds')) {
          return List<Cat>.from(data.map((catData) => Cat.fromJson(catData)));
        } else {
          print("No breed information found in the response");
          return [];
        }
      } else {
        throw Exception('Failed to load cats: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching cats: $e");
      return [];
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
          _catsList = snapshot.data as List<Cat>;

          return Scaffold(
            body: SizedBox.expand(
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  AppinioSwiper(
                    backgroundCardCount: 3,
                    swipeOptions: const SwipeOptions.symmetric(
                      horizontal: true,
                      vertical: false,
                    ),
                    maxAngle: 0,
                    controller: _swiperController,
                    onSwipeEnd: (previousIndex, targetIndex, activity) {
                      _swipeEnd(
                          previousIndex, targetIndex, activity, _catsList);
                    },
                    onEnd: _onEnd,
                    cardCount: _catsList.length,
                    cardBuilder: (BuildContext context, int index) {
                      return Card(
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _catsList[index].url,
                                fit: BoxFit.cover,
                                height: double.infinity,
                                width: double.infinity,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.cancel,
                                        size: 80, color: Colors.red),
                                    onPressed: () {
                                      _swiperController.swipeLeft();
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.check_circle,
                                        size: 80, color: Colors.green),
                                    onPressed: () {
                                      _swiperController.swipeRight();
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FloatingActionButton(
                      onPressed: () {
                        _toggleDetails();
                      },
                      child: Icon(_showDetails
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                    ),
                  ),
                ],
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

  void _swipeEnd(int previousIndex, int targetIndex, SwiperActivity activity,
      List<Cat> cats) {
    if (activity is Swipe) {
      setState(() {
        _currentIndex = previousIndex;

        if (activity.direction == AxisDirection.right) {
          addToFavorites(cats[_currentIndex].id);
        }
      });
    }
  }

  void _onEnd() {
    _cats = _fetchCats();
  }

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });

    if (_showDetails) {
      _showDetailsDialog(_catsList[_currentIndex]);
    }
  }

  void _showDetailsDialog(Cat cat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            cat.breed['name'] ?? 'Unknown Breed',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Origin: ${cat.breed['origin'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Description: ${cat.breed['description'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Life Span: ${cat.breed['life_span'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _showMoreDetailsDialog(cat.breed);
                },
                child: Text('Show More'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showMoreDetailsDialog(Map<String, dynamic> breedDetails) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            breedDetails['name'] ?? 'Unknown Breed',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temperament: ${breedDetails['temperament'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildDetailRow('Adaptability', breedDetails['adaptability']),
              _buildDetailRow(
                  'Affection Level', breedDetails['affection_level']),
              _buildDetailRow('Child Friendly', breedDetails['child_friendly']),
              _buildDetailRow(
                  'Stranger Friendly', breedDetails['stranger_friendly']),
              _buildDetailRow('Dog Friendly', breedDetails['dog_friendly']),
              _buildDetailRow('Energy Level', breedDetails['energy_level']),
              _buildDetailRow('Intelligence', breedDetails['intelligence']),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$title:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: value is int ? value / 5.0 : 0.0,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              backgroundColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
