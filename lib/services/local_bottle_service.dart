import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/bottle.dart';

class LocalBottleService {
  static final LocalBottleService instance = LocalBottleService._init();
  LocalBottleService._init();

  Future<Bottle> throwBottle(String content, String moodEmoji) async {
    final bottle = Bottle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      moodEmoji: moodEmoji,
      likesCount: 0,
      createdAt: DateTime.now().toIso8601String(),
    );
    await DiaryDatabaseHelper.instance.insertBottle(bottle);
    return bottle;
  }

  Future<Bottle?> pickRandomBottle() async {
    final bottle = await DiaryDatabaseHelper.instance.getRandomBottle();
    if (bottle == null) return null;
    final liked = await isLiked(int.parse(bottle.id));
    return Bottle(
      id: bottle.id,
      content: bottle.content,
      moodEmoji: bottle.moodEmoji,
      likesCount: bottle.likesCount,
      createdAt: bottle.createdAt,
      isLiked: liked,
    );
  }

  Future<void> likeBottle(String bottleId) async {
    await DiaryDatabaseHelper.instance.likeBottle(bottleId);
  }

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'device_user_id';
    String? id = prefs.getString(key);
    if (id == null) {
      id = DateTime.now().microsecondsSinceEpoch.toString();
      await prefs.setString(key, id);
    }
    return id;
  }

  Future<bool> isLiked(int bottleId) async {
    final deviceId = await _getDeviceId();
    return DiaryDatabaseHelper.instance.isLiked(bottleId, deviceId);
  }

  Future<bool> toggleLike(int bottleId) async {
    final deviceId = await _getDeviceId();
    return DiaryDatabaseHelper.instance.toggleLike(bottleId, deviceId);
  }
}
