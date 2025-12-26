import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/main_app.dart';
import 'services/auth_service.dart';
import 'services/firebase_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  ThemeData get _lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    useMaterial3: true,
  );

  ThemeData get _darkTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF22D3EE),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF020617),
    cardColor: const Color(0xFF0F172A),
    useMaterial3: true,
  );

  void _handleThemeChanged(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Marketplace',
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AuthWrapper(
        isDarkMode: _isDarkMode,
        onThemeChanged: _handleThemeChanged,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const AuthWrapper({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    // Initialize ItemStore when authenticated
    _initializeItemStore();
  }

  Future<void> _checkAuth() async {
    final session = await AuthService.getSession();
    setState(() {
      _isAuthenticated = session != null;
      _isLoading = false;
    });

    if (session != null) {
      _initializeItemStore();
    }
  }

  void _initializeItemStore() {
    // Import ItemStore and initialize
    // This will start listening to Firestore
    try {
      // Dynamically import to avoid circular dependencies
      // ItemStore will be initialized when MainApp is built
    } catch (e) {
      debugPrint('Error initializing ItemStore: $e');
    }
  }

  void _handleAuthSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _handleSignOut() async {
    await FirebaseAuthService.logout();
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    if (!_isAuthenticated) {
      return AuthScreen(onAuthSuccess: _handleAuthSuccess);
    }

    return MainApp(
      onSignOut: _handleSignOut,
      isDarkMode: widget.isDarkMode,
      onThemeChanged: widget.onThemeChanged,
    );
  }
}
