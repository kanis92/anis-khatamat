import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/bootstrap/firebase_bootstrap.dart';
import '../core/providers/auth_provider.dart';
import '../design_system/anis_design_system.dart';

const _kLoginHeroAsset = 'assets/branding/anis_login_hero.png';

/// Ratio [anis_login_hero.png] — 1269×413 px.
const _kLoginHeroAspectRatio = 1269 / 413;

/// Fond émeraude profond (#030E11) — bord source anis_header.
const _kLoginHeroEmeraldFill = Color(0xFF030E11);

/// Hero émeraude — artwork entier (contain), full-width, ancré en bas.
class _LoginBrandHero extends StatelessWidget {
  const _LoginBrandHero({required this.height, this.compact = false});

  final double height;
  final bool compact;

  static const double _artworkWidthFactor = 1.0;

  static const double _artworkWidthFactorCompact = 1.0;

  /// Dégage le Coran du chevauchement ivoire (_sheetOverlap = 28).
  static const double _artworkBottomClearance = 34;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: ColoredBox(
          color: _kLoginHeroEmeraldFill,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final drawW =
                  constraints.maxWidth *
                  (compact ? _artworkWidthFactorCompact : _artworkWidthFactor);

              return Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: compact ? 4 : 0,
                    bottom: _artworkBottomClearance,
                  ),
                  child: SizedBox(
                    width: drawW,
                    child: AspectRatio(
                      aspectRatio: _kLoginHeroAspectRatio,
                      child: Image.asset(
                        _kLoginHeroAsset,
                        fit: BoxFit.contain,
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

/// Feuille ivoire — formulaire de connexion.
class _LoginAuthSheet extends StatelessWidget {
  const _LoginAuthSheet({
    required this.colors,
    required this.text,
    required this.fieldHeight,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onRegister,
    required this.onDemo,
    required this.inputDecoration,
    required this.primaryButtonStyle,
  });

  final AnisColors colors;
  final AnisTypography text;
  final double fieldHeight;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onDemo;
  final InputDecoration Function({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  })
  inputDecoration;
  final ButtonStyle primaryButtonStyle;

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bienvenue',
              style: text.titleLarge.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AnisPalette.green800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AnisSpacing.xs),
            Text(
              'Connectez-vous pour poursuivre votre Khatma',
              style: text.bodySecondary.copyWith(
                fontSize: 15,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AnisSpacing.xl),
            SizedBox(
              height: fieldHeight,
              child: TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                style: text.body.copyWith(color: colors.textPrimary),
                decoration: inputDecoration(
                  label: 'Email',
                  prefixIcon: Icons.email_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
            ),
            const SizedBox(height: AnisSpacing.md),
            SizedBox(
              height: fieldHeight,
              child: TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) {
                  if (!isLoading) onLogin();
                },
                style: text.body.copyWith(color: colors.textPrimary),
                decoration: inputDecoration(
                  label: 'Mot de passe',
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: AnisIconSize.md,
                      color: colors.textSecondary,
                    ),
                    onPressed: onTogglePassword,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Mot de passe requis';
                  if (v.length < 6) return 'Minimum 6 caractères';
                  return null;
                },
              ),
            ),
            const SizedBox(height: AnisSpacing.xl),
            FilledButton(
              onPressed: isLoading ? null : onLogin,
              style: primaryButtonStyle,
              child:
                  isLoading
                      ? SizedBox(
                        height: AnisIconSize.lg,
                        width: AnisIconSize.lg,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textOnAction,
                        ),
                      )
                      : const Text('Se connecter'),
            ),
            const SizedBox(height: AnisSpacing.sm),
            TextButton(
              onPressed: onRegister,
              style: TextButton.styleFrom(
                foregroundColor: colors.actionSecondaryText,
                minimumSize: const Size(
                  double.infinity,
                  AnisIconSize.minTapTarget,
                ),
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: AnisSpacing.xs,
                ),
                textStyle: text.label.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.actionSecondaryText,
                ),
              ),
              child: const Text('Créer un compte'),
            ),
            const SizedBox(height: AnisSpacing.lg),
            const _LoginDividerLabel(label: 'Continuer autrement'),
            const SizedBox(height: AnisSpacing.sm),
            TextButton.icon(
              onPressed: onDemo,
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
                minimumSize: const Size(
                  double.infinity,
                  AnisIconSize.minTapTarget,
                ),
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: AnisSpacing.xs,
                ),
                textStyle: text.bodySecondary.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              icon: Icon(
                Icons.play_circle_outline,
                size: AnisIconSize.md,
                color: colors.actionSecondaryText,
              ),
              label: const Text('Découvrir en mode démo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginDividerLabel extends StatelessWidget {
  const _LoginDividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    return Row(
      children: [
        Expanded(child: Divider(color: colors.borderSubtle, height: 1)),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AnisSpacing.md,
          ),
          child: Text(
            label,
            style: text.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.borderSubtle, height: 1)),
      ],
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const double _fieldHeight = 58;
  static const double _primaryButtonHeight = 58;
  static const double _sheetOverlap = 28;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = tryFirebaseAuth();
    if (auth == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Firebase indisponible. Utilisez le mode démo ou relancez l’app.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final message = switch (e.code) {
          'user-not-found' => 'Aucun compte associé à cet email.',
          'wrong-password' => 'Mot de passe incorrect.',
          'invalid-email' => 'Email invalide.',
          _ => e.message ?? 'Erreur de connexion.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final colors = context.anisColors;
    final border = OutlineInputBorder(
      borderRadius: AnisRadius.lgAll,
      borderSide: BorderSide(
        color: colors.borderSubtle,
        width: AnisBorder.hairline,
      ),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.textSecondary),
      floatingLabelStyle: TextStyle(color: colors.borderFocus),
      prefixIcon: Icon(
        prefixIcon,
        size: AnisIconSize.md,
        color: colors.textSecondary,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colors.surfaceElevated,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AnisSpacing.lg,
        vertical: AnisSpacing.lg,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: AnisRadius.lgAll,
        borderSide: BorderSide(
          color: colors.borderFocus,
          width: AnisBorder.emphasis,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AnisRadius.lgAll,
        borderSide: BorderSide(
          color: colors.dangerBorder,
          width: AnisBorder.hairline,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AnisRadius.lgAll,
        borderSide: BorderSide(
          color: colors.dangerText,
          width: AnisBorder.emphasis,
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle(AnisColors colors, AnisTypography text) {
    return FilledButton.styleFrom(
      backgroundColor: colors.actionPrimary,
      foregroundColor: colors.textOnAction,
      disabledBackgroundColor: colors.actionDisabledSurface,
      disabledForegroundColor: colors.actionDisabledText,
      elevation: 0,
      minimumSize: const Size(double.infinity, _primaryButtonHeight),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AnisSpacing.xl,
      ),
      shape: RoundedRectangleBorder(borderRadius: AnisRadius.lgAll),
      textStyle: text.label.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textOnAction,
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colors.actionPrimaryPressed.withValues(alpha: 0.18);
        }
        return null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LoginBrandHero(height: heroHeight, compact: isCompact),
              Transform.translate(
                offset: const Offset(0, -_sheetOverlap),
                child: _LoginAuthSheet(
                  colors: colors,
                  text: text,
                  fieldHeight: _fieldHeight,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  isLoading: _isLoading,
                  onTogglePassword:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                  onLogin: _login,
                  onRegister: () => context.push('/register'),
                  onDemo:
                      () => ref.read(demoModeProvider.notifier).state = true,
                  inputDecoration: _inputDecoration,
                  primaryButtonStyle: _primaryButtonStyle(colors, text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
