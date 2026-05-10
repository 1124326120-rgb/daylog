import 'dart:math';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/diary_entry.dart';
import 'share_page.dart';

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return 'd ago';
  if (diff.inHours > 0) return 'h ago';
  if (diff.inMinutes > 0) return 'm ago';
  return 'just now';
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void _openSharePage() {
    final isWeekly = _tabController.index == 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShareReportPage(isWeekly: isWeekly),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Share this report",
            onPressed: () => _openSharePage(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Weekly"),
            Tab(text: "Monthly"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WeeklyReportView(),
          _MonthlyReportView(),
        ],
      ),
    );
  }
}

// ---------- Weekly Report ----------

class _WeeklyReportView extends StatefulWidget {
  @override
  State<_WeeklyReportView> createState() => _WeeklyReportViewState();
}

// Share button for report cards
class _WeeklyReportViewState extends State<_WeeklyReportView> {
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final entries = await DiaryDatabaseHelper.instance.getByWeek(now.year, now.month, now.day);
    if (mounted) setState(() { _entries = entries; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No entries this week', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Write some diary entries to see your weekly review!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final dateStr = '${_fmt(monday)} ~ ${_fmt(sunday)}';
    return _ReportCard(
      title: 'Weekly Review',
      subtitle: dateStr,
      entries: _entries,
      isWeekly: true,
    );
  }

  String _fmt(DateTime d) => '${d.month}/${d.day}';
}

// ---------- Monthly Report ----------

class _MonthlyReportView extends StatefulWidget {
  @override
  State<_MonthlyReportView> createState() => _MonthlyReportViewState();
}

class _MonthlyReportViewState extends State<_MonthlyReportView> {
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final entries = await DiaryDatabaseHelper.instance.getByMonth(now.year, now.month);
    if (mounted) setState(() { _entries = entries; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_view_month, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No entries this month', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month}';
    return _ReportCard(
      title: 'Monthly Review',
      subtitle: dateStr,
      entries: _entries,
      isWeekly: false,
    );
  }
}

// ---------- Report Card Widget ----------

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<DiaryEntry> entries;
  final bool isWeekly;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.isWeekly,
  });

  // Extract top 5 keywords by simple word frequency
  List<_Keyword> _getTopKeywords() {
    final stopWords = {'the', 'a', 'an', 'is', 'was', 'are', 'were', 'in', 'on', 'at',
      'to', 'for', 'of', 'and', 'or', 'but', 'it', 'this', 'that', 'with', 'from',
      'by', 'be', 'have', 'has', 'had', 'do', 'does', 'did', 'not', 'no', 'i',
      'my', 'me', 'we', 'our', 'you', 'your', 'he', 'she', 'they', 'them', 'their',
      'will', 'can', 'just', 'like', 'very', 'really', 'also', 'so', 'up', 'all',
      '的', '了', '是', '在', '我', '有', '和', '就', '不', '人', '都', '一', '一个',
      '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看',
      '好', '自己', '这', '他', '她', '它', '们', '那', '些', '来', '出', '过',
      '吧', '吗', '啊', '呢', '哦', '嗯', '哈', '啦', '呀', '因为', '所以', '但是',
      '然后', '虽然', '如果', '可以', '已经', '什么', '怎么', '为什么', '时候',
      '今天', '明天', '昨天', '时间', '东西', '事情', '地方', '这个', '那个',
    };

    final wordCount = <String, int>{};
    for (final entry in entries) {
      final words = entry.content
          .replaceAll(RegExp(r'[^\w\u4e00-\u9fff]'), ' ')
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.length >= 2 && !stopWords.contains(w));
      for (final word in words) {
        wordCount[word] = (wordCount[word] ?? 0) + 1;
      }
    }

    final sorted = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => _Keyword(e.key, e.value)).toList();
  }

  // Mood distribution
  Map<String, int> _getMoodDistribution() {
    final moodCount = <String, int>{};
    for (final entry in entries) {
      moodCount[entry.moodEmoji] = (moodCount[entry.moodEmoji] ?? 0) + 1;
    }
    return moodCount;
  }

  // Calculate longest consecutive days
  int _longestStreak() {
    if (entries.isEmpty) return 0;
    final dates = entries.map((e) => DateTime.parse(e.date)).toSet().toList()
      ..sort();
    int maxStreak = 1;
    int currentStreak = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        currentStreak++;
        if (currentStreak > maxStreak) maxStreak = currentStreak;
      } else {
        currentStreak = 1;
      }
    }
    return maxStreak;
  }

  // Weekly mood aggregation
  List<_WeekMood> _getWeeklyMoods() {
    if (entries.isEmpty) return [];
    final now = DateTime.now();
    final weeks = <int, List<String>>{};
    for (final entry in entries) {
      final dt = DateTime.parse(entry.date);
      final weekOfMonth = ((dt.day - 1) ~/ 7) + 1;
      weeks.putIfAbsent(weekOfMonth, () => []).add(entry.moodEmoji);
    }
    return weeks.entries.map((e) {
      final freq = <String, int>{};
      for (final m in e.value) {
        freq[m] = (freq[m] ?? 0) + 1;
      }
      final top = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return _WeekMood(e.key, top.isNotEmpty ? top.first.key : '😐', e.value.length);
    }).toList()..sort((a, b) => a.week.compareTo(b.week));
  }

  @override
  Widget build(BuildContext context) {
    final moodDist = _getMoodDistribution();
    final keywords = _getTopKeywords();
    final weeklyMoods = !isWeekly ? _getWeeklyMoods() : [];
    final streak = !isWeekly ? _longestStreak() : 0;

    // Find most meaningful entry (most favorite or most liked)
    DiaryEntry? bestEntry;
    final favorites = entries.where((e) => e.isFavorite == 1).toList();
    if (favorites.isNotEmpty) {
      bestEntry = favorites.first;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: RepaintBoundary(
        key: const ValueKey('report_card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    )),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${entries.length} entries',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mood distribution
            Text('Mood Distribution', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: moodDist.entries.map((e) {
                    final total = entries.length;
                    final pct = (e.value / total * 100).round();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text('$pct%', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Keywords
            if (keywords.isNotEmpty) ...[
              Text('Top Keywords', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: keywords.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${e.key + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.value.word, style: const TextStyle(fontSize: 16))),
                          Text('x${e.value.count}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Monthly-specific: longest streak
            if (!isWeekly) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Longest Streak', style: Theme.of(context).textTheme.titleSmall),
                          Text('$streak consecutive days', style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Monthly mood trend (by week)
              Text('Mood Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: weeklyMoods.map((wm) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text('Week ${wm.week}', style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          Text(wm.mood, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text('(${wm.count} entries)', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Most meaningful diary
            if (bestEntry != null) ...[
              Text('Most Meaningful', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(bestEntry.moodEmoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(bestEntry.date, style: Theme.of(context).textTheme.bodySmall),
                          const Spacer(),
                          const Icon(Icons.favorite, color: Colors.red, size: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bestEntry.content.length > 100
                            ? '${bestEntry.content.substring(0, 100)}...'
                            : bestEntry.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Keyword {
  final String word;
  final int count;
  _Keyword(this.word, this.count);
}

class _WeekMood {
  final int week;
  final String mood;
  final int count;
  _WeekMood(this.week, this.mood, this.count);
}
