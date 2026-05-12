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
    return DiaryDatabaseHelper.instance.getRandomBottle();
  }

  Future<void> likeBottle(String bottleId) async {
    await DiaryDatabaseHelper.instance.likeBottle(bottleId);
  }
}
