import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Stream<List<String>> _favoritesStream;

  @override
  void initState() {
    super.initState();
    _favoritesStream = _getFavoritesStream();
  }

  Stream<List<String>> _getFavoritesStream() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .snapshots()
          .map((snapshot) {
        final favoriteCatIds = snapshot.docs.map((doc) {
          final catId = doc.id;
          return catId;
        }).toList();

        return favoriteCatIds;
      });
    } else {
      return Stream.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<String>>(
        stream: _favoritesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            final List<String> favoriteCatIds = snapshot.data ?? [];
            return _buildFavoritesGrid(favoriteCatIds);
          }
        },
      ),
    );
  }

  Widget _buildFavoritesGrid(List<String> favoriteCatIds) {
    return FutureBuilder(
      future: _getCatDataList(favoriteCatIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData) {
          final List<Map<String, dynamic>> catDataList = snapshot.data as List<Map<String, dynamic>>;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
            ),
            itemCount: catDataList.length,
            itemBuilder: (context, index) {
              final catData = catDataList[index];
              return CatItem(
                catData: catData,
                onTap: () {
                  _showInitialDetailsDialog(context, catData);
                },
              );
            },
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getCatDataList(List<String> catIds) async {
    final List<Future<Map<String, dynamic>>> futures = [];
    for (final catId in catIds) {
      futures.add(_getCatData(catId));
    }

    return Future.wait(futures);
  }

  Future<Map<String, dynamic>> _getCatData(String catId) async {
    final apiUrl = 'https://api.thecatapi.com/v1/images/$catId';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load cat data: ${response.statusCode}');
    }
  }

  void _showInitialDetailsDialog(BuildContext context, Map<String, dynamic> catData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(catData['url']),
              Text('Breed: ${catData['breeds'][0]['name']}'),
              Text('Origin: ${catData['breeds'][0]['origin']}'),
              Text('Description: ${catData['breeds'][0]['description']}'),
              ElevatedButton(
                onPressed: () {
                  _showMoreDetailsDialog(context, catData['breeds'][0]);
                },
                child: const Text('Show More'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoreDetailsDialog(BuildContext context, Map<String, dynamic> breedDetails) {
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
              _buildDetailRow('Affection Level', breedDetails['affection_level']),
              _buildDetailRow('Child Friendly', breedDetails['child_friendly']),
              _buildDetailRow('Stranger Friendly', breedDetails['stranger_friendly']),
              _buildDetailRow('Dog Friendly', breedDetails['dog_friendly']),
              _buildDetailRow('Energy Level', breedDetails['energy_level']),
              _buildDetailRow('Intelligence', breedDetails['intelligence']),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
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

class CatItem extends StatelessWidget {
  final Map<String, dynamic> catData;
  final VoidCallback onTap;

  const CatItem({required this.catData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String catImageUrl = catData['url'] as String;
    final String catId = catData['id'] as String;

    return Card(
      child: InkWell(
        onTap: () => onTap(),
        child: Image.network(catImageUrl, fit: BoxFit.cover),
      ),
    );
  }
}
