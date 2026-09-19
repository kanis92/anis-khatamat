import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/l10n_extensions.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/auth_service.dart';
import '../core/widgets/anis_auth_brand_hero.dart';
import '../core/widgets/auth_provider_leading_icon.dart';
import '../design_system/anis_design_system.dart';

enum _AuthLoading { google, apple }

/// Carte d'authentification premium (alignée sur la feuille login).
class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.loading,
    required this.errorMessage,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    required this.onEmailSignIn,
    required this.showAppleButton,
  });

  final _AuthLoading? loading;

  bool get _isBusy => loading != null;
  final String? errorMessage;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;
  final VoidCallback onEmailSignIn;
  final bool showAppleButton;

  static const double _buttonHeight = 58;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: AnisElevation.subtle(colors.shadow),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          AnisSpacing.page,
          AnisSpacing.xxl,
          AnisSpacing.page,
          bottomInset > 0 ? AnisSpacing.lg : AnisSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.authWelcomeTitle,
              style: text.titleLarge.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AnisPalette.green800,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AnisSpacing.xs),
            Text(
              l10n.authWelcomeSubtitle,
              style: text.bodySecondary.copyWith(
                fontSize: 15,
                color: colors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AnisSpacing.xl),
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
              const SizedBox(height: AnisSpacing.lg),
            ],
            _AuthProviderButton(
              onPressed: _isBusy ? null : onGoogleSignIn,
              kind: AuthProviderLeadingKind.google,
              label: l10n.authContinueWithGoogle,
              colors: colors,
              text: text,
              isLoading: loading == _AuthLoading.google,
            ),
            const SizedBox(height: AnisSpacing.sm),
            if (showAppleButton) ...[
              _AuthProviderButton(
                onPressed: _isBusy ? null : onAppleSignIn,
                kind: AuthProviderLeadingKind.apple,
                label: l10n.authContinueWithApple,
                colors: colors,
                text: text,
                isDark: true,
                isLoading: loading == _AuthLoading.apple,
              ),
              const SizedBox(height: AnisSpacing.sm),
            ],
            _AuthDivider(label: l10n.authOr, colors: colors, text: text),
            const SizedBox(height: AnisSpacing.sm),
            OutlinedButton(
              onPressed: _isBusy ? null : onEmailSignIn,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.borderStrong),
                minimumSize: const Size(double.infinity, _buttonHeight),
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
          ],
        ),
      ),
    );
  }
}

class _AuthProviderButton extends StatelessWidget {
  const _AuthProviderButton({
    required this.onPressed,
    required this.kind,
    required this.label,
    required this.colors,
    required this.text,
    this.isDark = false,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final AuthProviderLeadingKind kind;
  final String label;
  final AnisColors colors;
  final AnisTypography text;
  final bool isDark;
  final bool isLoading;

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
        minimumSize: const Size(double.infinity, _AuthCard._buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? Colors.black : colors.borderStrong,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child:
          isLoading && onPressed != null
              ? SizedBox(
                height: AnisIconSize.lg,
                width: AnisIconSize.lg,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.white : colors.actionPrimary,
                ),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthProviderLeadingIcon(
                    kind: kind,
                    monochromeLight: isDark,
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
  _AuthLoading? _loading;
  String? _errorMessage;

  bool get _isLoading => _loading != null;

  bool get _showAppleButton {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _loading = _AuthLoading.google;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _loading = null;
    });

    _applyAuthResult(result);
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _loading = _AuthLoading.apple;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithApple();

    if (!mounted) return;

    setState(() {
      _loading = null;
    });

    _applyAuthResult(result);
  }

  void _applyAuthResult(AuthResult result) {
    final l10n = context.l10n;
    switch (result) {
      case AuthSuccess():
      case AuthCancelled():
        break;
      case AuthAccountCollision(:final email):
        setState(() {
          _errorMessage = l10n.authErrorAccountCollision(email);
        });
      case AuthNetworkFailure():
        setState(() {
          _errorMessage = l10n.authErrorNetwork;
        });
      case AuthProviderFailure(:final message):
        setState(() {
          _errorMessage = message;
        });
      case AuthConfigurationFailure():
        setState(() {
          _errorMessage = l10n.authErrorConfiguration;
        });
    }
  }

  void _handleEmailSignIn() {
    context.push('/login');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenHeight < 700;
    final heroHeight = anisAuthHeroHeight(screenHeight, compact: isCompact);

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnisAuthBrandHero(height: heroHeight, compact: isCompact),
            Transform.translate(
              offset: const Offset(0, -kAnisAuthSheetOverlap),
              child: _AuthCard(
                loading: _loading,
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
