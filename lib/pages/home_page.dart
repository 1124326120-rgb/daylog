import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/database_helper.dart';
import '../models/diary_entry.dart';
import 'edit_diary_page.dart';
import 'diary_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final entries = await DiaryDatabaseHelper.instance.getAll();
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DayLog'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _showCalendar(context),
            tooltip: 'Calendar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : _buildDiaryList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEdit(context),
        icon: const Icon(Icons.edit),
        label: const Text('New Diary'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No diary entries yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to write your first diary entry!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryList() {
    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Text(
                entry.moodEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              title: Text(
                entry.content.length > 50
                    ? '...'
                    : entry.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Row(
                children: [
                  Text(entry.date),
                  if (entry.isFavorite == 1) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.favorite, size: 14, color: Colors.red.withValues(alpha: 0.6)),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiaryDetailPage(entry: entry),
                  ),
                );
                _loadEntries();
              },
            ),
          );
        },
      ),
    );
  }

  void _showCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalendarPage()),
    ).then((_) => _loadEntries());
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditDiaryPage()),
    );
    _loadEntries();
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<DiaryEntry>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final entries = await DiaryDatabaseHelper.instance.getAll();
    final events = <DateTime, List<DiaryEntry>>{};
    for (final entry in entries) {
      final dt = DateTime.parse(entry.date);
      final dateKey = DateTime(dt.year, dt.month, dt.day);
      events.putIfAbsent(dateKey, () => []).add(entry);
    }
    setState(() => _events = events);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) => _events[day] ?? [],
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _navigateToDay(selectedDay);
            },
            calendarStyle: CalendarStyle(
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDay(DateTime day) {
    final dateStr = '--';
    final entries = _events[DateTime(day.year, day.month, day.day)] ?? [];
    if (entries.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiaryDetailPage(entry: entries.first),
        ),
      );
    }
  }
}
