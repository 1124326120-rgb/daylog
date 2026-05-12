import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/diary_entry.dart';
import 'diary_detail_page.dart';
import '../l10n/app_localizations.dart';

class ThisDayLastYear extends StatefulWidget {
  const ThisDayLastYear({super.key});

  @override
  State<ThisDayLastYear> createState() => _ThisDayLastYearState();
}

class _ThisDayLastYearState extends State<ThisDayLastYear> {
  DiaryEntry? _entry;
  bool _isLoading = true;
  String _lastYearDate = '';

  @override
  void initState() {
    super.initState();
    _loadLastYearEntry();
  }

  Future<void> _loadLastYearEntry() async {
    final now = DateTime.now();
    final lastYear = DateTime(now.year - 1, now.month, now.day);
    final dateStr = "${lastYear.year}-${lastYear.month.toString().padLeft(2, '0')}-${lastYear.day.toString().padLeft(2, '0')}";
    _lastYearDate = dateStr;

    final entry = await DiaryDatabaseHelper.instance.getByDate(dateStr);
    if (mounted) setState(() { _entry = entry; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.thisDayLastYear)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entry == null
              ? _buildEmptyState(l10n)
              : _buildEntry(),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noEntryLastYear,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.noEntryLastYearHint}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Year difference badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppLocalizations.of(context).fromOneYearAgo,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 16),

          // Diary card
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiaryDetailPage(entry: _entry!),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji and date
                    Row(
                      children: [
                        Text(_entry!.moodEmoji, style: const TextStyle(fontSize: 40)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_entry!.date, style: Theme.of(context).textTheme.titleMedium),
                            Text(AppLocalizations.of(context).oneYearAgo, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Content
                    Text(
                      _entry!.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).tapToViewFull,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
