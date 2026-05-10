import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/diary_entry.dart';
import 'edit_diary_page.dart';

class DiaryDetailPage extends StatefulWidget {
  final DiaryEntry entry;

  const DiaryDetailPage({super.key, required this.entry});

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  late DiaryEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  Future<void> _toggleFavorite() async {
    final updated = _entry.copyWith(
      isFavorite: _entry.isFavorite == 1 ? 0 : 1,
      updatedAt: DateTime.now(),
    );
    await DiaryDatabaseHelper.instance.update(updated);
    setState(() => _entry = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_entry.date),
        actions: [
          IconButton(
            icon: Icon(
              _entry.isFavorite == 1 ? Icons.favorite : Icons.favorite_border,
              color: _entry.isFavorite == 1 ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
            tooltip: 'Mark as meaningful',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => EditDiaryPage(entry: _entry),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    _entry.moodEmoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _entry.date,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_entry.isFavorite == 1) ...[
                    const SizedBox(height: 4),
                    Chip(
                      avatar: const Icon(Icons.favorite, size: 16, color: Colors.red),
                      label: const Text('Meaningful'),
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              _entry.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
            ),
            if (_entry.imagePath != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _entry.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Diary'),
        content: const Text('Are you sure you want to delete this diary entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await DiaryDatabaseHelper.instance.delete(_entry.id!);
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
