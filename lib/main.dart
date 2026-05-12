import "package:flutter/material.dart";
import "database/database_helper.dart";
import "pages/home_page.dart";
import "pages/edit_diary_page.dart";
import "pages/bottle_page.dart";
import "pages/settings_page.dart";
import "services/notification_service.dart";
import "l10n/app_localizations.dart";
import "providers/locale_provider.dart";

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

class DayLogApp extends StatefulWidget {
  const DayLogApp({super.key});

  @override
  State<DayLogApp> createState() => _DayLogAppState();
}

class _DayLogAppState extends State<DayLogApp> {
  final LocaleProvider _localeProvider = LocaleProvider();

  @override
  void initState() {
    super.initState();
    _localeProvider.addListener(_onLocaleChange);
  }

  @override
  void dispose() {
    _localeProvider.removeListener(_onLocaleChange);
    super.dispose();
  }

  void _onLocaleChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "DayLog",
      locale: _localeProvider.locale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
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
      home: MainScaffold(localeProvider: _localeProvider),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final LocaleProvider localeProvider;

  const MainScaffold({super.key, required this.localeProvider});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = <Widget>[
      const HomePage(),
      const EditDiaryPage(),
      const BottlePage(),
      ProfilePage(localeProvider: widget.localeProvider),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.edit_note_outlined),
            selectedIcon: const Icon(Icons.edit_note),
            label: l10n.write,
          ),
          NavigationDestination(
            icon: const Icon(Icons.water_drop_outlined),
            selectedIcon: const Icon(Icons.water_drop),
            label: l10n.bottle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
