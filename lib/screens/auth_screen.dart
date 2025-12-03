import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../widgets/app_scaffold.dart';

enum AuthState {
  signIn,
  signUp,
  confirmSignUp,
  forgotPassword,
  confirmResetPassword,
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  AuthState _authState = AuthState.signIn;
  bool _isLoading = false;
  bool _isCheckingAuth = true;
  String _error = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final result = await Amplify.Auth.fetchAuthSession();
      if (result.isSignedIn && mounted) {
        context.go('/protected/profile');
      }
    } catch (e) {
      safePrint('Auth check error: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _clearMessages() {
    setState(() {
      _error = '';
      _successMessage = '';
    });
  }

  void _showError(String message) {
    setState(() {
      _error = message;
      _successMessage = '';
    });
  }

  void _showSuccess(String message) {
    setState(() {
      _successMessage = message;
      _error = '';
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmation code is required';
    }
    if (value.length < 6) {
      return 'Enter a valid confirmation code';
    }
    return null;
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    _clearMessages();
    setState(() => _isLoading = true);

    try {
      final result = await Amplify.Auth.signIn(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (result.isSignedIn) {
          await Provider.of<AppAuthProvider>(context, listen: false)
              .checkAuthStatus();
          context.go('/protected/profile');
        } else {
          _showError('Sign in incomplete. Please try again.');
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    _clearMessages();
    setState(() => _isLoading = true);

    try {
      final result = await Amplify.Auth.signUp(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: _emailController.text.trim(),
          },
        ),
      );

      if (mounted) {
        if (result.isSignUpComplete) {
          // Auto sign-in if no confirmation needed
          setState(() => _authState = AuthState.signIn);
          _showSuccess('Account created successfully! Please sign in.');
        } else {
          // Need confirmation
          setState(() => _authState = AuthState.confirmSignUp);
          _showSuccess('Confirmation code sent to your email!');
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    _clearMessages();
    setState(() => _isLoading = true);

    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: _usernameController.text.trim(),
        confirmationCode: _codeController.text.trim(),
      );

      if (mounted) {
        if (result.isSignUpComplete) {
          setState(() => _authState = AuthState.signIn);
          _showSuccess('Email confirmed! Please sign in.');
          _codeController.clear();
        } else {
          _showError('Confirmation incomplete. Please try again.');
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendConfirmationCode() async {
    if (_usernameController.text.trim().isEmpty) {
      _showError('Please enter your email');
      return;
    }

    _clearMessages();
    setState(() => _isLoading = true);

    try {
      await Amplify.Auth.resendSignUpCode(
        username: _usernameController.text.trim(),
      );
      _showSuccess('Confirmation code resent to your email!');
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Failed to resend code. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    _clearMessages();
    setState(() => _isLoading = true);

    try {
      final result = await Amplify.Auth.resetPassword(
        username: _usernameController.text.trim(),
      );

      if (mounted) {
        setState(() => _authState = AuthState.confirmResetPassword);
        _showSuccess('Reset code sent to your email!');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    _clearMessages();
    setState(() => _isLoading = true);

    try {
      await Amplify.Auth.confirmResetPassword(
        username: _usernameController.text.trim(),
        newPassword: _newPasswordController.text,
        confirmationCode: _codeController.text.trim(),
      );

      if (mounted) {
        setState(() => _authState = AuthState.signIn);
        _showSuccess('Password reset successfully! Please sign in.');
        _passwordController.clear();
        _newPasswordController.clear();
        _codeController.clear();
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getTitle() {
    switch (_authState) {
      case AuthState.signIn:
        return 'Sign In';
      case AuthState.signUp:
        return 'Create Account';
      case AuthState.confirmSignUp:
        return 'Confirm Sign Up';
      case AuthState.forgotPassword:
        return 'Reset Password';
      case AuthState.confirmResetPassword:
        return 'Confirm New Password';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking authentication status...'),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/Four_Color_Logo-300x300.webp',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 50),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  Text(
                    _getTitle(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF13345C),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error message
                  if (_error.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Success message
                  if (_successMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        _successMessage,
                        style: const TextStyle(color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (_authState == AuthState.signIn) ..._buildSignInForm(),
                  if (_authState == AuthState.signUp) ..._buildSignUpForm(),
                  if (_authState == AuthState.confirmSignUp)
                    ..._buildConfirmSignUpForm(),
                  if (_authState == AuthState.forgotPassword)
                    ..._buildForgotPasswordForm(),
                  if (_authState == AuthState.confirmResetPassword)
                    ..._buildConfirmResetPasswordForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSignInForm() {
    return [
      TextFormField(
        controller: _usernameController,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email_outlined),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: _validateEmail,
        enabled: !_isLoading,
      ),
      const SizedBox(height: 15),
      TextFormField(
        controller: _passwordController,
        decoration: const InputDecoration(
          labelText: 'Password',
          prefixIcon: Icon(Icons.lock_outlined),
          border: OutlineInputBorder(),
        ),
        obscureText: true,
        textInputAction: TextInputAction.done,
        validator: _validatePassword,
        enabled: !_isLoading,
        onFieldSubmitted: (_) => _signIn(),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF13345C),
            padding: const EdgeInsets.all(15),
            disabledBackgroundColor: Colors.grey,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Sign In',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
      const SizedBox(height: 15),
      TextButton(
        onPressed: _isLoading
            ? null
            : () {
                _clearMessages();
                setState(() => _authState = AuthState.forgotPassword);
              },
        child: const Text('Forgot Password?',
            style: TextStyle(color: Color(0xFF3498DB))),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Don't have an account? ",
              style: TextStyle(color: Colors.grey)),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    _clearMessages();
                    setState(() => _authState = AuthState.signUp);
                  },
            child: const Text('Sign Up',
                style: TextStyle(
                    color: Color(0xFF13345C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSignUpForm() {
    return [
      TextFormField(
        controller: _usernameController,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email_outlined),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: _validateEmail,
        enabled: !_isLoading,
        onChanged: (text) {
          // Sync username and email like React Native
          _emailController.text = text;
        },
      ),
      const SizedBox(height: 15),
      TextFormField(
        controller: _passwordController,
        decoration: const InputDecoration(
          labelText: 'Password',
          prefixIcon: Icon(Icons.lock_outlined),
          border: OutlineInputBorder(),
          helperText: 'Minimum 8 characters',
        ),
        obscureText: true,
        textInputAction: TextInputAction.done,
        validator: _validatePassword,
        enabled: !_isLoading,
        onFieldSubmitted: (_) => _signUp(),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _signUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF13345C),
            padding: const EdgeInsets.all(15),
            disabledBackgroundColor: Colors.grey,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Sign Up',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Already have an account? ',
              style: TextStyle(color: Colors.grey)),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    _clearMessages();
                    setState(() => _authState = AuthState.signIn);
                  },
            child: const Text('Sign In',
                style: TextStyle(
                    color: Color(0xFF13345C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildConfirmSignUpForm() {
    return [
      const Text(
        "We've sent a confirmation code to your email. Please enter it below.",
        style: TextStyle(fontSize: 14, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _usernameController,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email_outlined),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: _validateEmail,
        enabled: !_isLoading,
      ),
      const SizedBox(height: 15),
      TextFormField(
        controller: _codeController,
        decoration: const InputDecoration(
          labelText: 'Confirmation Code',
          prefixIcon: Icon(Icons.key_outlined),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        validator: _validateCode,
        enabled: !_isLoading,
        onFieldSubmitted: (_) => _confirmSignUp(),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _confirmSignUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF13345C),
            padding: const EdgeInsets.all(15),
            disabledBackgroundColor: Colors.grey,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Confirm',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: _isLoading ? null : _resendConfirmationCode,
        child: const Text('Resend Code',
            style: TextStyle(color: Color(0xFF3498DB))),
      ),
      TextButton(
        onPressed: _isLoading
            ? null
            : () {
                _clearMessages();
                setState(() => _authState = AuthState.signIn);
              },
        child: const Text('Back to Sign In',
            style: TextStyle(
                color: Color(0xFF13345C), fontWeight: FontWeight.bold)),
      ),
    ];
  }

  List<Widget> _buildForgotPasswordForm() {
    return [
      const Text(
        "Enter your email and we'll send you a code to reset your password.",
        style: TextStyle(fontSize: 14, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _usernameController,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email_outlined),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        validator: _validateEmail,
        enabled: !_isLoading,
        onFieldSubmitted: (_) => _forgotPassword(),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _forgotPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF13345C),
            padding: const EdgeInsets.all(15),
            disabledBackgroundColor: Colors.grey,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Send Code',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: _isLoading
            ? null
            : () {
                _clearMessages();
                setState(() => _authState = AuthState.signIn);
              },
        child: const Text('Back to Sign In',
            style: TextStyle(
                color: Color(0xFF13345C), fontWeight: FontWeight.bold)),
      ),
    ];
  }

  List<Widget> _buildConfirmResetPasswordForm() {
    return [
      const Text(
        'Enter the code sent to your email and your new password.',
        style: TextStyle(fontSize: 14, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _usernameController,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email_outlined),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: _validateEmail,
        enabled: !_isLoading,
      ),
      const SizedBox(height: 15),
      TextFormField(
        controller: _codeController,
        decoration: const InputDecoration(
          labelText: 'Confirmation Code',
          prefixIcon: Icon(Icons.key_outlined),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        validator: _validateCode,
        enabled: !_isLoading,
      ),
      const SizedBox(height: 15),
      TextFormField(
        controller: _newPasswordController,
        decoration: const InputDecoration(
          labelText: 'New Password',
          prefixIcon: Icon(Icons.lock_outlined),
          border: OutlineInputBorder(),
          helperText: 'Minimum 8 characters',
        ),
        obscureText: true,
        textInputAction: TextInputAction.done,
        validator: _validatePassword,
        enabled: !_isLoading,
        onFieldSubmitted: (_) => _confirmResetPassword(),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _confirmResetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF13345C),
            padding: const EdgeInsets.all(15),
            disabledBackgroundColor: Colors.grey,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Reset Password',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: _isLoading
            ? null
            : () {
                _clearMessages();
                setState(() => _authState = AuthState.signIn);
              },
        child: const Text('Back to Sign In',
            style: TextStyle(
                color: Color(0xFF13345C), fontWeight: FontWeight.bold)),
      ),
    ];
  }
}
