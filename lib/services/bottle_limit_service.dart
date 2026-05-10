import 'package:shared_preferences/shared_preferences.dart';

class BottleLimitService {
  static final BottleLimitService instance = BottleLimitService._init();
  BottleLimitService._init();

  static const String _throwCountKey = 'bottle_throw_count';
  static const String _pickCountKey = 'bottle_pick_count';
  static const String _throwDateKey = 'bottle_throw_date';
  static const String _pickDateKey = 'bottle_pick_date';

  static const int maxThrowsPerDay = 3;
  static const int maxPicksPerDay = 3;

  /// Check if user can throw a bottle today
  Future<bool> canThrow() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_throwDateKey) ?? '';
    if (savedDate != today) {
      await prefs.setInt(_throwCountKey, 0);
      await prefs.setString(_throwDateKey, today);
      return true;
    }
    final count = prefs.getInt(_throwCountKey) ?? 0;
    return count < maxThrowsPerDay;
  }

  /// Record a throw
  Future<void> recordThrow() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_throwDateKey) ?? '';
    if (savedDate != today) {
      await prefs.setInt(_throwCountKey, 1);
      await prefs.setString(_throwDateKey, today);
    } else {
      final count = (prefs.getInt(_throwCountKey) ?? 0) + 1;
      await prefs.setInt(_throwCountKey, count);
    }
  }

  /// Get remaining throws today
  Future<int> getRemainingThrows() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_throwDateKey) ?? '';
    if (savedDate != today) return maxThrowsPerDay;
    final count = prefs.getInt(_throwCountKey) ?? 0;
    return (maxThrowsPerDay - count).clamp(0, maxThrowsPerDay);
  }

  /// Check if user can pick a bottle today
  Future<bool> canPick() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_pickDateKey) ?? '';
    if (savedDate != today) {
      await prefs.setInt(_pickCountKey, 0);
      await prefs.setString(_pickDateKey, today);
      return true;
    }
    final count = prefs.getInt(_pickCountKey) ?? 0;
    return count < maxPicksPerDay;
  }

  /// Record a pick
  Future<void> recordPick() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_pickDateKey) ?? '';
    if (savedDate != today) {
      await prefs.setInt(_pickCountKey, 1);
      await prefs.setString(_pickDateKey, today);
    } else {
      final count = (prefs.getInt(_pickCountKey) ?? 0) + 1;
      await prefs.setInt(_pickCountKey, count);
    }
  }

  /// Get remaining picks today
  Future<int> getRemainingPicks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_pickDateKey) ?? '';
    if (savedDate != today) return maxPicksPerDay;
    final count = prefs.getInt(_pickCountKey) ?? 0;
    return (maxPicksPerDay - count).clamp(0, maxPicksPerDay);
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

