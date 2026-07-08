import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';
import 'services/connectivity_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  String? initError;

  try {
    // Initialize Firebase (requires google-services.json on Android)
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e) {
    initError = e.toString();
    print("Firebase Initialization failed: $e");
  }

  runApp(SureThingNetApp(
    firebaseInitialized: firebaseInitialized,
    initError: initError,
  ));
}

class SureThingNetApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? initError;

  const SureThingNetApp({
    Key? key,
    required this.firebaseInitialized,
    this.initError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Core services
    final firebaseService = FirebaseService();
    final connectivityService = ConnectivityService();

    // Trigger anonymous sign in immediately if Firebase initialized successfully
    if (firebaseInitialized) {
      firebaseService.signInAnonymously();
    }

    return MaterialApp(
      title: 'SureThingNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF34C759), // Mint Green
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF34C759),
          secondary: Color(0xFFFF9500), // Amber
          background: Color(0xFF121212),
          surface: Color(0xFF1E1E1E),
          error: Color(0xFFFF3B30), // Red
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontFamily: 'Inter'),
          bodyMedium: TextStyle(fontFamily: 'Inter'),
        ),
      ),
      home: firebaseInitialized
          ? HomeScreen(
              firebaseService: firebaseService,
              connectivityService: connectivityService,
            )
          : FirebaseSetupGuideScreen(errorDetails: initError),
    );
  }
}

/// Fallback screen shown when Firebase config file is missing
class FirebaseSetupGuideScreen extends StatelessWidget {
  final String? errorDetails;

  const FirebaseSetupGuideScreen({Key? key, this.errorDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 72,
                color: Color(0xFFFF3B30),
              ),
              const SizedBox(height: 24),
              const Text(
                'Firebase Config Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'SureThingNet requires a Firebase project configuration to sync network audits.',
                style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SETUP INSTRUCTIONS:',
                      style: TextStyle(color: Color(0xFFFF9500), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Go to your Firebase Console and register the Android app with package name:\n   com.surethingnet.stn\n'
                      '2. Download the google-services.json config file.\n'
                      '3. Save it to:\n   surethingnet-android/android/app/google-services.json\n'
                      '4. Re-build and launch the application.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              if (errorDetails != null) ...[
                const SizedBox(height: 24),
                ExpansionTile(
                  title: const Text('Error Logs', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        errorDetails!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
