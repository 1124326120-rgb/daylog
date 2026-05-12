import "package:flutter/material.dart";
import "dart:typed_data";
import "dart:io";
import "package:share_plus/share_plus.dart";
import "package:path_provider/path_provider.dart";
import "dart:ui" as ui;
import "package:flutter/rendering.dart";
import "package:intl/intl.dart";
import "../database/database_helper.dart";
import "../models/diary_entry.dart";
import "../l10n/app_localizations.dart";

class ShareReportPage extends StatefulWidget {
  final bool isWeekly;

  const ShareReportPage({super.key, required this.isWeekly});

  @override
  State<ShareReportPage> createState() => _ShareReportPageState();
}

class _ShareReportPageState extends State<ShareReportPage> {
  final GlobalKey _repaintKey = GlobalKey();
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    List<DiaryEntry> entries;
    if (widget.isWeekly) {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final allEntries = await DiaryDatabaseHelper.instance.getAll();
      entries = allEntries.where((e) {
        final d = DateTime.tryParse(e.date);
        if (d == null) return false;
        return !d.isBefore(monday) && !d.isAfter(sunday);
      }).toList();
    } else {
      entries = await DiaryDatabaseHelper.instance.getByMonth(now.year, now.month);
    }
    if (mounted) setState(() { _entries = entries; _isLoading = false; });
  }

  Future<void> _share() async {
    setState(() => _isSharing = true);

    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Could not capture widget");

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Could not capture image");

      final tempDir = await getTemporaryDirectory();
      final fileName = "daylog_report_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File("${tempDir.path}/$fileName");
      await file.writeAsBytes(byteData.buffer.asUint8List());

      final l10n = AppLocalizations.of(context);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.isWeekly ? l10n.myWeekOnDayLog : l10n.myMonthOnDayLog,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Share failed: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.isWeekly ? l10n.weeklyReview : l10n.monthlyReview)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isWeekly ? l10n.weeklyReview : l10n.monthlyReview),
        actions: [
          IconButton(
            onPressed: _isSharing ? null : _share,
            icon: _isSharing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            tooltip: l10n.share,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: _repaintKey,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.isWeekly ? l10n.weeklyReview : l10n.monthlyReview,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat("yyyy/MM/dd").format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const Divider(height: 32),
                Text(
                  "${_entries.length}",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.entriesCount,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 24),

                // Show mood summary
                Text(
                  l10n.moodDistribution,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _entries
                      .map((e) => e.moodEmoji)
                      .where((e) => e.isNotEmpty)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) => Text(entry.value, style: const TextStyle(fontSize: 24)))
                      .toList(),
                ),
                const SizedBox(height: 24),

                // Tagline
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.madeWithDayLog,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
