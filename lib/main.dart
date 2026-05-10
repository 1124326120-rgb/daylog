import "package:flutter/material.dart";
import "database/database_helper.dart";
import "pages/home_page.dart";
import "pages/edit_diary_page.dart";
import "pages/bottle_page.dart";
import "pages/settings_page.dart"; // exports ProfilePage
import "services/notification_service.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DiaryDatabaseHelper.instance.initialize();
  await NotificationService.instance.initialize();
  // Re-schedule reminder if enabled
  final enabled = await NotificationService.instance.isReminderEnabled();
  if (enabled) {
    final time = await NotificationService.instance.getReminderTime();
    if (time != null) {
      await NotificationService.instance.scheduleDailyReminder(time.hour, time.minute);
    }
  }
  runApp(const DayLogApp());
}

class DayLogApp extends StatelessWidget {
  const DayLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "DayLog",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4CAF50),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF4CAF50),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    EditDiaryPage(),
    BottlePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: "Write",
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: "Bottle",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}




