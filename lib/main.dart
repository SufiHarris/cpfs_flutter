import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart'; // ADD THIS

import 'core/constants/app_routes.dart';
import 'core/shared/amplify_configuration.dart';
import 'providers/app_auth_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _amplifyConfigured = false;
  String? _configError;

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      // Check if already configured (hot reload protection)
      if (Amplify.isConfigured) {
        safePrint('Amplify was already configured');
        setState(() => _amplifyConfigured = true);
        return;
      }

      // Add the Auth plugin
      final authPlugin = AmplifyAuthCognito();
      await Amplify.addPlugin(authPlugin);

      // Add the API plugin
      final apiPlugin = AmplifyAPI();
      await Amplify.addPlugin(apiPlugin);

      // Add the Storage plugin (NEW)
      final storagePlugin = AmplifyStorageS3();
      await Amplify.addPlugin(storagePlugin);

      // Configure Amplify with your configuration
      await Amplify.configure(amplifyconfig);

      safePrint('Successfully configured Amplify with Auth, API, and Storage');
      setState(() => _amplifyConfigured = true);
    } on AmplifyAlreadyConfiguredException {
      safePrint('Amplify was already configured. Proceeding...');
      setState(() => _amplifyConfigured = true);
    } catch (e) {
      safePrint('Error configuring Amplify: $e');
      setState(() {
        _configError = e.toString();
        _amplifyConfigured = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while configuring Amplify
    if (!_amplifyConfigured && _configError == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/Four_Color_Logo-300x300.webp',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.image, size: 50),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF13345C)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initializing app...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF13345C),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show error screen if configuration failed
    if (_configError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to Initialize',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF13345C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _configError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _configError = null;
                        _amplifyConfigured = false;
                      });
                      _configureAmplify();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF13345C),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Main app - Amplify is configured
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppAuthProvider(),
        ),
      ],
      child: Consumer<AppAuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'CPFS Marketplace',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: const Color(0xFF13345C),
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
              fontFamily: 'OpenSans',
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF13345C),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13345C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF13345C),
                    width: 2,
                  ),
                ),
              ),
            ),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
