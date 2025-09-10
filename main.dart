import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_page.dart';
import 'screens/profile_screen.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;

// Replace with your actual API key
const String GEMINI_API_KEY = 'AIzaSyBRKyZKaWYM7k7EepuqNglTNIDIu87gmCc';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set OpenFoodFacts user agent
  off.OpenFoodAPIConfiguration.userAgent = off.UserAgent(
    name: 'MyFlutterApp', // Replace with your app name
  );

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Force sign out on app start
    await FirebaseAuth.instance.signOut();
    print('Firebase initialized and signed out');

    // Initialize Gemini here
    Gemini.init(
      apiKey: GEMINI_API_KEY,
      enableDebugging: true, // Optional: for debugging
    );
    print('Gemini initialized');

    // Clear SharedPreferences to ensure onboarding is shown
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('SharedPreferences cleared');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const HealthApp());
}

class HealthApp extends StatelessWidget {
  const HealthApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        fontFamily: 'Poppins',
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasSeenOnboarding = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('AuthWrapper initState called');
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      print('Checking onboarding status...');
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool('hasSeenOnboarding') ?? false;
      print('Onboarding status from SharedPreferences: $hasSeen');

      // Double check auth state
      final currentUser = FirebaseAuth.instance.currentUser;
      print('Current user after sign out: ${currentUser?.uid}');

      if (currentUser != null) {
        print('Forcing sign out again...');
        await FirebaseAuth.instance.signOut();
      }

      setState(() {
        _hasSeenOnboarding = hasSeen;
        _isLoading = false;
      });
      print('State updated - hasSeenOnboarding: $_hasSeenOnboarding');
    } catch (e) {
      print('Error in _checkOnboardingStatus: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markOnboardingComplete() async {
    try {
      print('Marking onboarding as complete...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);
      print('Onboarding marked as complete in SharedPreferences');
      setState(() {
        _hasSeenOnboarding = true;
      });
      print('State updated - hasSeenOnboarding: $_hasSeenOnboarding');
    } catch (e) {
      print('Error marking onboarding complete: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        'Building AuthWrapper - isLoading: $_isLoading, hasSeenOnboarding: $_hasSeenOnboarding');

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If user hasn't seen onboarding, show it regardless of auth state
    if (!_hasSeenOnboarding) {
      print('Showing onboarding screen - user has not seen onboarding');
      return OnboardingScreen(
        onComplete: () {
          print('Onboarding complete callback called');
          _markOnboardingComplete();
        },
      );
    }

    // After onboarding, check auth state
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('Auth state changed: ${snapshot.connectionState}');
        print('Has error: ${snapshot.hasError}');
        print('Has data: ${snapshot.hasData}');
        print('User: ${snapshot.data?.uid}');

        // Show error if there's an error in the stream
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        // If user is authenticated, show profile screen
        if (snapshot.hasData) {
          print('User is authenticated: ${snapshot.data?.uid}');
          return const ProfileScreen();
        }

        // If user is not authenticated, show auth page
        print('Showing auth page - user is not authenticated');
        return const AuthPage();
      },
    );
  }
}
