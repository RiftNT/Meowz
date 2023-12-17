import 'dart:convert';
import 'package:http/http.dart' as http;

class Cat {
  String id;
  String url;
  int width;
  int height;
  List<Breed> breeds;

  Cat({
    required this.id,
    required this.url,
    required this.width,
    required this.height,
    required this.breeds,
  });

  factory Cat.fromJson(Map<String, dynamic> json) {
    return Cat(
      id: json['id'],
      url: json['url'],
      width: json['width'],
      height: json['height'],
      breeds: List<Breed>.from(json['breeds'].map((x) => Breed.fromJson(x))),
    );
  }

  static Future<Cat> fetchCat() async {
    final response = await http.get(
        'https://api.thecatapi.com/v1/images/search?has_breeds=1&api_key=live_ww8GBeUHkAu51IVO2DmnEPwoPj8hOPVoetILTJHlSWIvWYx8H1r1W8ZJvtkLAwZR'
            as Uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return Cat.fromJson(data[0]);
    } else {
      throw Exception('Failed to load cat');
    }
  }
}

class Breed {
  String id;
  String name;

  Breed({required this.id, required this.name});

  factory Breed.fromJson(Map<String, dynamic> json) {
    return Breed(
      id: json['id'],
      name: json['name'],
    );
  }
}
