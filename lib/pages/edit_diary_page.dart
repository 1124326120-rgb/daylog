import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "../database/database_helper.dart";
import "../models/diary_entry.dart";
import "../l10n/app_localizations.dart";

class EditDiaryPage extends StatefulWidget {
  final DiaryEntry? entry;

  const EditDiaryPage({super.key, this.entry});

  @override
  State<EditDiaryPage> createState() => _EditDiaryPageState();
}

class _EditDiaryPageState extends State<EditDiaryPage> {
  late TextEditingController _contentController;
  late TextEditingController _titleController;
  String _selectedMood = '\u{1F60A}';
  String? _imagePath;
  final _formKey = GlobalKey<FormState>();
  bool _alsoThrowBottle = false;

  static const List<String> _moods = [
    '\u{1F60A}', '\u{1F610}', '\u{1F622}', '\u{1F621}',
    '\u{1F634}', '\u{1F970}', '\u{1F914}', '\u{1F64F}',
  ];

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.entry?.content ?? "");
    _titleController = TextEditingController(text: widget.entry?.title ?? "");
    if (widget.entry != null) {
      _selectedMood = widget.entry!.moodEmoji;
      _imagePath = widget.entry!.imagePath;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final content = _contentController.text.trim();
    final title = _titleController.text.trim();
    final dateStr = _getTodayDate();

    final entry = DiaryEntry(
      id: widget.entry?.id,
      date: dateStr,
      title: title.isEmpty ? null : title,
      content: content,
      moodEmoji: _selectedMood,
      imagePath: _imagePath,
      isFavorite: widget.entry?.isFavorite ?? 0,
    );

    if (widget.entry == null) {
      await DiaryDatabaseHelper.instance.insert(entry);
    } else {
      await DiaryDatabaseHelper.instance.update(entry);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saved)),
      );
    }

    // Only pop if we were pushed as a route (not as a tab)
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.pop(context, true);
    } else if (mounted) {
      // Tab mode: clear form instead
      _contentController.clear();
      _titleController.clear();
      setState(() {
        _selectedMood = '\u{1F60A}';
        _imagePath = null;
      });
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Photo Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() => _imagePath = image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to pick image: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? l10n.newDiaryTitle : l10n.editDiaryTitle),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTodayDate(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              // Title field
              Text(l10n.titleLabel, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: l10n.titleHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Mood selector
              Text(l10n.howAreYouFeeling, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _moods.map((emoji) {
                  final isSelected = _selectedMood == emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )]
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Photo picker
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(l10n.addPhoto),
                  ),
                  if (_imagePath != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.check, size: 16),
                      label: Text(l10n.photoSelected),
                      onDeleted: () => setState(() => _imagePath = null),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              // Content
              Text(l10n.diaryContent, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: l10n.writeThoughts,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseWriteSomething;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Also throw bottle switch
              Card(
                child: SwitchListTile(
                  title: Text(l10n.alsoThrowBottle),
                  subtitle: Text(l10n.bottleSubtitle),
                  secondary: const Icon(Icons.water_drop_outlined),
                  value: _alsoThrowBottle,
                  onChanged: widget.entry != null
                      ? null
                      : (val) => setState(() => _alsoThrowBottle = val),
                ),
              ),
              if (widget.entry != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.bottleOnlyNew,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
