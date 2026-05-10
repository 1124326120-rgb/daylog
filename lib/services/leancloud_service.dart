import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/bottle.dart';

class LeanCloudService {
  static final LeanCloudService instance = LeanCloudService._init();
  LeanCloudService._init();

  // CONFIG: Replace these with your own LeanCloud credentials
  // Sign up at https://console.leancloud.app/ to get your App ID and Key
  static const String _appId = 'YOUR_LEANCLOUD_APP_ID';
  static const String _appKey = 'YOUR_LEANCLOUD_APP_KEY';
  static const String _baseUrl = 'https://YOUR_APP_ID.lc-cn-n1-shared.com/1.1/classes/Bottle';

  Map<String, String> get _headers => {
        'X-LC-Id': _appId,
        'X-LC-Key': _appKey,
        'Content-Type': 'application/json',
      };

  /// Throw a bottle (POST /classes/Bottle)
  Future<Bottle> throwBottle(String content, String moodEmoji) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        'content': content,
        'moodEmoji': moodEmoji,
        'likesCount': 0,
      }),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return Bottle(
        id: json['objectId'] ?? '',
        content: content,
        moodEmoji: moodEmoji,
        likesCount: 0,
        createdAt: json['createdAt'] ?? '',
      );
    }
    throw Exception('Failed to throw bottle: ${response.statusCode} ${response.body}');
  }

  /// Pick a random bottle (GET /classes/Bottle with random skip)
  Future<Bottle> pickRandomBottle() async {
    // First, get total count
    final countResponse = await http.get(
      Uri.parse('$_baseUrl?count=1&limit=0'),
      headers: _headers,
    );

    if (countResponse.statusCode != 200) {
      throw Exception('Failed to get bottle count');
    }

    final countJson = jsonDecode(countResponse.body);
    final total = countJson['count'] as int? ?? 0;

    if (total == 0) {
      throw Exception('No bottles in the sea');
    }

    final randomSkip = Random().nextInt(total); // total >= 1 here (checked above)

    final response = await http.get(
      Uri.parse('$_baseUrl?limit=1&skip=$randomSkip'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final results = json['results'] as List? ?? [];
      if (results.isEmpty) {
        throw Exception('No bottles found');
      }
      return Bottle.fromJson(results[0]);
    }
    throw Exception('Failed to pick bottle: ${response.statusCode}');
  }

  /// Like a bottle (PUT /classes/Bottle/<objectId> — increment likesCount)
  Future<void> likeBottle(String bottleId) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$bottleId'),
      headers: _headers,
      body: jsonEncode({
        'likesCount': {'__op': 'Increment', 'amount': 1},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to like bottle: ${response.statusCode}');
    }
  }
}

