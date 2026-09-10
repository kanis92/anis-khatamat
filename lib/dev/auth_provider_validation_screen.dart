import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';

/// Minimal auth-only screen for provider validation.
///
/// Does NOT:
/// - Create Firestore profiles
/// - Navigate to ANIS home
/// - Access business data
/// - Call ANIS REST APIs
///
/// Only displays Firebase Auth result.
class AuthProviderValidationScreen extends StatefulWidget {
  const AuthProviderValidationScreen({super.key});

  @override
  State<AuthProviderValidationScreen> createState() =>
      _AuthProviderValidationScreenState();
}

class _AuthProviderValidationScreenState
    extends State<AuthProviderValidationScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AuthSuccess():
        // Success: Firebase.currentUser will be updated via stream
        break;
      case AuthCancelled():
        // User cancelled: no error message needed
        break;
      case AuthAccountCollision(:final email):
        setState(() {
          _errorMessage = 'Account collision: $email already exists';
        });
      case AuthNetworkFailure(:final message):
        setState(() {
          _errorMessage = 'Network error: $message';
        });
      case AuthProviderFailure(:final message):
        setState(() {
          _errorMessage = 'Google Sign-In failed: $message';
        });
      case AuthConfigurationFailure(:final message):
        setState(() {
          _errorMessage = 'Configuration error: $message';
        });
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.signInWithApple();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AuthSuccess():
        // Success: Firebase.currentUser will be updated via stream
        break;
      case AuthCancelled():
        // User cancelled: no error message needed
        break;
      case AuthAccountCollision(:final email):
        setState(() {
          _errorMessage = 'Account collision: $email already exists';
        });
      case AuthNetworkFailure(:final message):
        setState(() {
          _errorMessage = 'Network error: $message';
        });
      case AuthProviderFailure(:final message):
        setState(() {
          _errorMessage = 'Apple Sign-In failed: $message';
        });
      case AuthConfigurationFailure(:final message):
        setState(() {
          _errorMessage = 'Configuration error: $message';
        });
    }
  }

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ANIS — Auth Provider Validation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _currentUser == null
                  ? _buildSignInView()
                  : _buildSignedInView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.security,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Provider Validation',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Debug-only harness for testing real Google and Apple Sign-In',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[900]),
            ),
          ),
          const SizedBox(height: 24),
        ],
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleGoogleSignIn,
          icon: const Icon(Icons.login),
          label: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sign in with Google'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleAppleSignIn,
          icon: const Icon(Icons.apple),
          label: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sign in with Apple'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSignedInView() {
    final user = _currentUser!;
    final providerData = user.providerData
        .map((p) => p.providerId)
        .where((id) => id != 'firebase')
        .join(', ');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle,
          size: 64,
          color: Colors.green[600],
        ),
        const SizedBox(height: 24),
        Text(
          'Authenticated',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildInfoTile('Firebase UID', user.uid),
        _buildInfoTile('Email', user.email ?? '(not provided)'),
        _buildInfoTile('Display Name', user.displayName ?? '(not set)'),
        _buildInfoTile('Email Verified', user.emailVerified.toString()),
        _buildInfoTile('Provider(s)', providerData.isEmpty ? 'none' : providerData),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          '✅ Auth validation successful',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ),
        Text(
          'No Firestore profile created\nNo business data accessed',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: _handleSignOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
