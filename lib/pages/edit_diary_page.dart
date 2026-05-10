import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "../database/database_helper.dart";
import "../models/diary_entry.dart";
import "../services/leancloud_service.dart";

class EditDiaryPage extends StatefulWidget {
  final DiaryEntry? entry;

  const EditDiaryPage({super.key, this.entry});

  @override
  State<EditDiaryPage> createState() => _EditDiaryPageState();
}

class _EditDiaryPageState extends State<EditDiaryPage> {
  late TextEditingController _contentController;
  String _selectedMood = String.fromCharCodes([0x1F60A]);
  String? _imagePath;
  final _formKey = GlobalKey<FormState>();
  bool _alsoThrowBottle = false;

  static const List<String> _moods = [
    String.fromCharCodes([0x1F60A]), String.fromCharCodes([0x1F610]), String.fromCharCodes([0x1F622]), String.fromCharCodes([0x1F621]),
    String.fromCharCodes([0x1F634]), String.fromCharCodes([0x1F970]), String.fromCharCodes([0x1F914]), String.fromCharCodes([0x1F64F]),
  ];

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.entry?.content ?? "");
    if (widget.entry != null) {
      _selectedMood = widget.entry!.moodEmoji;
      _imagePath = widget.entry!.imagePath;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final content = _contentController.text.trim();
    final dateStr = _getTodayDate();

    final entry = DiaryEntry(
      id: widget.entry?.id,
      date: dateStr,
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

    // If "also throw bottle" is checked, send to LeanCloud
    if (_alsoThrowBottle && widget.entry == null) {
      try {
        await LeanCloudService.instance.throwBottle(content, _selectedMood);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Diary saved and thrown into the sea! ")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Diary saved, but bottle throw failed: ${e.toString()}")),
          );
        }
      }
    }

    if (mounted) Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? "New Diary" : "Edit Diary"),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
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
              Text("How are you feeling?", style: Theme.of(context).textTheme.titleSmall),
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
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Add Photo"),
                  ),
                  if (_imagePath != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.check, size: 16),
                      label: const Text("Photo selected"),
                      onDeleted: () => setState(() => _imagePath = null),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text("Diary Content", style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: "Write your thoughts here...",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please write something";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Also throw bottle switch
              Card(
                child: SwitchListTile(
                  title: const Text("Also throw into the sea"),
                  subtitle: const Text("Share this diary entry anonymously as a bottle"),
                  secondary: const Icon(Icons.water_drop_outlined),
                  value: _alsoThrowBottle,
                  onChanged: widget.entry != null
                      ? null  // only for new entries
                      : (val) => setState(() => _alsoThrowBottle = val),
                ),
              ),
              if (widget.entry != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Bottle sharing is only available for new diary entries.",
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
