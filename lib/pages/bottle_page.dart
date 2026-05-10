import "package:flutter/material.dart";


import "dart:math";
import "../models/bottle.dart";
import "../services/leancloud_service.dart";
import "../services/bottle_limit_service.dart";


class BottlePage extends StatefulWidget {
  const BottlePage({super.key});

  @override
  State<BottlePage> createState() => _BottlePageState();
}

class _BottlePageState extends State<BottlePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _remainingThrows = 3;
  int _remainingPicks = 5;
  bool _isPicking = false;
  Bottle? _pickedBottle;
  bool _showBottle = false;
  String? _errorMessage;

  // Throw form state
  final _contentController = TextEditingController();
  String _selectedMood = String.fromCharCodes([0x1F60A]);
  bool _isThrowing = false;

  static const List<String> _moods = [
    String.fromCharCodes([0x1F60A]),
    String.fromCharCodes([0x1F610]),
    String.fromCharCodes([0x1F622]),
    String.fromCharCodes([0x1F621]),
    String.fromCharCodes([0x1F634]),
    String.fromCharCodes([0x1F970]),
    String.fromCharCodes([0x1F914]),
    String.fromCharCodes([0x1F64F]),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLimits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadLimits() async {
    final remainingThrows = await BottleLimitService.instance.getRemainingThrows();
    final remainingPicks = await BottleLimitService.instance.getRemainingPicks();
    if (mounted) {
      setState(() {
        _remainingThrows = remainingThrows;
        _remainingPicks = remainingPicks;
      });
    }
  }

  Future<void> _throwBottle() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write something in your bottle")),
      );
      return;
    }

    final canThrow = await BottleLimitService.instance.canThrow();
    if (!canThrow) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Daily limit reached! You can only throw 3 bottles per day.")),
      );
      return;
    }

    setState(() => _isThrowing = true);

    try {
      await LeanCloudService.instance.throwBottle(
        _contentController.text.trim(),
        _selectedMood,
      );
      await BottleLimitService.instance.recordThrow();
      await _loadLimits();
      _contentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bottle thrown into the sea! "),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isThrowing = false);
    }
  }

  Future<void> _pickBottle() async {
    final canPick = await BottleLimitService.instance.canPick();
    if (!canPick) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Daily limit reached! You can only pick 3 bottles per day.")),
      );
      return;
    }

    setState(() {
      _isPicking = true;
      _showBottle = false;
      _pickedBottle = null;
      _errorMessage = null;
    });

    try {
      final bottle = await LeanCloudService.instance.pickRandomBottle();
      await BottleLimitService.instance.recordPick();
      await _loadLimits();

      // Simulate picking animation delay
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _pickedBottle = bottle;
          _isPicking = false;
          _showBottle = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPicking = false;
          _errorMessage = "No bottles in the sea yet. Be the first to throw one!";
        });
      }
    }
  }

  Future<void> _likeBottle() async {
    if (_pickedBottle == null) return;
    try {
      await LeanCloudService.instance.likeBottle(_pickedBottle!.id);
      if (mounted) {
        setState(() {
          _pickedBottle = Bottle(
            id: _pickedBottle!.id,
            content: _pickedBottle!.content,
            moodEmoji: _pickedBottle!.moodEmoji,
            likesCount: _pickedBottle!.likesCount + 1,
            createdAt: _pickedBottle!.createdAt,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Liked! "),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to like: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bottle"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Pick"),
            Tab(text: "Throw"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPickTab(),
          _buildThrowTab(),
        ],
      ),
    );
  }

  Widget _buildPickTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Remaining picks indicator
          Text(
            "Picks remaining today: $_remainingPicks",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),

          // Pick button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isPicking || _remainingPicks <= 0 ? null : _pickBottle,
              icon: _isPicking
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.water_drop, size: 28),
              label: Text(
                _isPicking ? "Fishing..." : "Pick a Bottle",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Picked bottle display (card flip animation simulation)
          if (_isPicking)
            _buildPickingAnimation(),

          if (_showBottle && _pickedBottle != null)
            _buildBottleCard(),

          if (_errorMessage != null)
            _buildEmptyState(_errorMessage!),
        ],
      ),
    );
  }

  Widget _buildPickingAnimation() {
    return Center(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(value * pi),
                child: Card(
                  elevation: 8,
                  child: Container(
                    width: 200,
                    height: 260,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.water_drop,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5 - (value * 0.3)),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            "Searching the sea...",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottleCard() {
    final bottle = _pickedBottle!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primaryContainer,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Bottle header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.water_drop, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "A Message in a Bottle",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.water_drop, color: Theme.of(context).colorScheme.primary, size: 20),
                ],
              ),
              const Divider(height: 32),

              // Mood emoji
              Text(
                bottle.moodEmoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),

              // Content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bottle.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Likes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _likeBottle,
                    icon: Icon(
                      Icons.favorite,
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                    iconSize: 32,
                  ),
                  Text(
                    "${bottle.likesCount}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),

              // Date
              Text(
                "Drifted in: ${bottle.createdAt.length > 10 ? bottle.createdAt.substring(0, 10) : bottle.createdAt}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Throw Tab ----------

  Widget _buildThrowTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Remaining throws indicator
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Throws remaining today: $_remainingThrows",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mood emoji selector
          Text(
            "Your Mood",
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Content input
          Text(
            "Message (max 280 chars)",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: 5,
            maxLength: 280,
            decoration: const InputDecoration(
              hintText: "Write a message to put in your bottle...",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Throw button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isThrowing || _remainingThrows <= 0 ? null : _throwBottle,
              icon: _isThrowing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, size: 24),
              label: Text(
                _isThrowing ? "Throwing..." : "Throw into the Sea",
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




