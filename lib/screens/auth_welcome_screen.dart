import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/l10n_extensions.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/auth_service.dart';
import '../design_system/anis_design_system.dart';

const _kAuthHeroAsset = 'assets/branding/anis_login_hero.png';
const _kAuthHeroAspectRatio = 1269 / 413;
const _kAuthHeroEmeraldFill = Color(0xFF030E11);

/// Hero émeraude ANIS — même cadrage que [LoginScreen] (_LoginBrandHero).
class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.height, this.compact = false});

  final double height;
  final bool compact;

  static const double _artworkBottomClearance = 34;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: ColoredBox(
          color: _kAuthHeroEmeraldFill,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: compact ? 4 : 0,
                    bottom: _artworkBottomClearance,
                  ),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: AspectRatio(
                      aspectRatio: _kAuthHeroAspectRatio,
                      child: Image.asset(
                        _kAuthHeroAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                        filterQuality: FilterQuality.high,
                        semanticLabel: 'ANIS Khatamat',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Carte d'authentification premium.
class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.isLoading,
    required this.errorMessage,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    required this.onEmailSignIn,
    required this.showAppleButton,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;
  final VoidCallback onEmailSignIn;
  final bool showAppleButton;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome message
          Text(
            l10n.authWelcomeTitle,
            style: text.titleLarge.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.authWelcomeSubtitle,
            style: text.bodySecondary.copyWith(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Error message
          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.dangerSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.dangerBorder),
              ),
              child: Text(
                errorMessage!,
                style: text.bodySecondary.copyWith(
                  fontSize: 13,
                  color: colors.dangerText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Google button
          _AuthProviderButton(
            onPressed: isLoading ? null : onGoogleSignIn,
            icon: 'assets/icons/google_logo.png',
            label: l10n.authContinueWithGoogle,
            colors: colors,
            text: text,
          ),
          const SizedBox(height: 12),

          // Apple button (iOS/macOS only)
          if (showAppleButton) ...[
            _AuthProviderButton(
              onPressed: isLoading ? null : onAppleSignIn,
              icon: 'assets/icons/apple_logo.png',
              label: l10n.authContinueWithApple,
              colors: colors,
              text: text,
              isDark: true,
            ),
            const SizedBox(height: 12),
          ],

          // Divider
          _AuthDivider(label: l10n.authOr, colors: colors, text: text),
          const SizedBox(height: 12),

          // Email button
          OutlinedButton(
            onPressed: isLoading ? null : onEmailSignIn,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              side: BorderSide(color: colors.borderStrong),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              l10n.authContinueWithEmail,
              style: text.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),

          // Loading indicator
          if (isLoading) ...[
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.actionPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

/// Bouton fournisseur d'authentification.
class _AuthProviderButton extends StatelessWidget {
  const _AuthProviderButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.colors,
    required this.text,
    this.isDark = false,
  });

  final VoidCallback? onPressed;
  final String icon;
  final String label;
  final AnisColors colors;
  final AnisTypography text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        disabledBackgroundColor: colors.surfaceElevated,
        disabledForegroundColor: colors.textSecondary,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? Colors.black : colors.borderStrong,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            icon,
            height: 20,
            width: 20,
            errorBuilder: (_, __, ___) => Icon(
              Icons.login,
              size: 20,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: text.label.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Diviseur avec label.
class _AuthDivider extends StatelessWidget {
  const _AuthDivider({
    required this.label,
    required this.colors,
    required this.text,
  });

  final String label;
  final AnisColors colors;
  final AnisTypography text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: colors.borderSubtle, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: text.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.borderSubtle, height: 1)),
      ],
    );
  }
}

/// Écran d'accueil authentification ANIS.
class AuthWelcomeScreen extends ConsumerStatefulWidget {
  const AuthWelcomeScreen({super.key});

  @override
  ConsumerState<AuthWelcomeScreen> createState() => _AuthWelcomeScreenState();
}

class _AuthWelcomeScreenState extends ConsumerState<AuthWelcomeScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  bool get _showAppleButton {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AuthSuccess():
        // Router will automatically redirect to home
        break;

      case AuthCancelled():
        // User cancelled, no error message
        break;

      case AuthAccountCollision(:final email):
        setState(() {
          _errorMessage = context.l10n.authErrorAccountCollision(email);
        });
        break;

      case AuthNetworkFailure():
        setState(() {
          _errorMessage = context.l10n.authErrorNetwork;
        });
        break;

      case AuthProviderFailure():
        setState(() {
          _errorMessage = context.l10n.authErrorProvider;
        });
        break;

      case AuthConfigurationFailure():
        setState(() {
          _errorMessage = context.l10n.authErrorConfiguration;
        });
        break;
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithApple();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case AuthSuccess():
        // Router will automatically redirect to home
        break;

      case AuthCancelled():
        // User cancelled, no error message
        break;

      case AuthAccountCollision(:final email):
        setState(() {
          _errorMessage = context.l10n.authErrorAccountCollision(email);
        });
        break;

      case AuthNetworkFailure():
        setState(() {
          _errorMessage = context.l10n.authErrorNetwork;
        });
        break;

      case AuthProviderFailure():
        setState(() {
          _errorMessage = context.l10n.authErrorProvider;
        });
        break;

      case AuthConfigurationFailure():
        setState(() {
          _errorMessage = context.l10n.authErrorConfiguration;
        });
        break;
    }
  }

  void _handleEmailSignIn() {
    context.push('/login');
  }

  static const double _sheetOverlap = 28;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenHeight < 700;

    final heroHeight = (screenHeight * (isCompact ? 0.29 : 0.31)).clamp(
      isCompact ? 196.0 : 210.0,
      isCompact ? 248.0 : 278.0,
    );

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthHero(height: heroHeight, compact: isCompact),
            Transform.translate(
              offset: const Offset(0, -_sheetOverlap),
              child: _AuthCard(
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                onGoogleSignIn: _handleGoogleSignIn,
                onAppleSignIn: _handleAppleSignIn,
                onEmailSignIn: _handleEmailSignIn,
                showAppleButton: _showAppleButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
