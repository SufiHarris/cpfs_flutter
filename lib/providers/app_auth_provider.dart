import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class AppAuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  AuthUser? _currentUser;
  String? _userEmail;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  AuthUser? get currentUser => _currentUser;
  String? get userEmail => _userEmail;

  AppAuthProvider() {
    _initialize();
  }

  /// Initialize and check auth status
  Future<void> _initialize() async {
    // Add small delay to ensure Amplify is fully ready
    await Future.delayed(const Duration(milliseconds: 200));
    await checkAuthStatus();
  }

  /// Check current authentication status
  Future<void> checkAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try to get current user - this is more reliable than fetchAuthSession
      _currentUser = await Amplify.Auth.getCurrentUser();
      _isAuthenticated = true;

      // Try to get user attributes for email
      try {
        final attributes = await Amplify.Auth.fetchUserAttributes();
        for (var attr in attributes) {
          if (attr.userAttributeKey == AuthUserAttributeKey.email) {
            _userEmail = attr.value;
            break;
          }
        }
      } catch (e) {
        safePrint('Could not fetch user attributes: $e');
      }

      safePrint('User authenticated: ${_currentUser?.userId}');
    } on AuthException catch (e) {
      // User is not signed in - this is expected
      safePrint('Not authenticated: ${e.message}');
      _isAuthenticated = false;
      _currentUser = null;
      _userEmail = null;
    } catch (e) {
      // Unexpected error
      safePrint('Unexpected error checking auth: $e');
      _isAuthenticated = false;
      _currentUser = null;
      _userEmail = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out the current user
  Future<bool> signOut() async {
    try {
      final result = await Amplify.Auth.signOut();

      if (result is CognitoCompleteSignOut) {
        safePrint('Sign out completed successfully');
      } else if (result is CognitoFailedSignOut) {
        safePrint('Sign out failed: ${result.exception}');
      }

      // Always reset state
      _isAuthenticated = false;
      _currentUser = null;
      _userEmail = null;
      notifyListeners();

      return true;
    } on AuthException catch (e) {
      safePrint('Error signing out: ${e.message}');

      // Force reset state even on error
      _isAuthenticated = false;
      _currentUser = null;
      _userEmail = null;
      notifyListeners();

      return false;
    } catch (e) {
      safePrint('Unexpected sign out error: $e');

      // Force reset state
      _isAuthenticated = false;
      _currentUser = null;
      _userEmail = null;
      notifyListeners();

      return false;
    }
  }

  /// Refresh the authentication session
  Future<void> refreshSession() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();

      if (session.isSignedIn) {
        _currentUser = await Amplify.Auth.getCurrentUser();
        _isAuthenticated = true;

        // Refresh user attributes
        try {
          final attributes = await Amplify.Auth.fetchUserAttributes();
          for (var attr in attributes) {
            if (attr.userAttributeKey == AuthUserAttributeKey.email) {
              _userEmail = attr.value;
              break;
            }
          }
        } catch (e) {
          safePrint('Could not refresh user attributes: $e');
        }
      } else {
        _isAuthenticated = false;
        _currentUser = null;
        _userEmail = null;
      }

      notifyListeners();
    } catch (e) {
      safePrint('Error refreshing session: $e');
    }
  }

  /// Update user after successful sign in
  Future<void> onSignInSuccess() async {
    await checkAuthStatus();
  }
}
