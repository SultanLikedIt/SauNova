import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/core.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  StreamSubscription? _authEventsSubscription;

  bool _loading = false;
  bool _isGoogleLoading = false;
  bool _showEmailLogin = false;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() async {
    await _googleSignIn.initialize();

    _authEventsSubscription = _googleSignIn.authenticationEvents.listen(
      _onGoogleAuthenticationEvent,
      onError: _onGoogleAuthenticationError,
    );
  }

  Future<void> _onGoogleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    if (user == null || !_isGoogleLoading) {
      if (_isGoogleLoading) {
        setState(() => _isGoogleLoading = false);
      }
      return;
    }

    try {
      final GoogleSignInAuthentication googleAuth = user.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await ref.read(coreProvider.notifier).continueWithGoogle(credential);

      final route = ref.read(coreProvider.notifier).getRoute();

      if (!mounted || route == '/login') return;

      Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
    } catch (e) {
      _showErrorDialog(
        'Google Sign-In Failed',
        'Unable to sign in with Google. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _onGoogleAuthenticationError(Object error) {
    if (!mounted) return;

    setState(() {
      _isGoogleLoading = false;
    });

    String message = 'An unknown error occurred during Google Sign-In.';
    if (error is GoogleSignInException) {
      message = switch (error.code) {
        GoogleSignInExceptionCode.canceled => 'Sign in was cancelled.',
        _ => 'Google Sign-In Error: ${error.code.name}',
      };
    }
    _showErrorDialog('Google Sign-In Error', message);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      // Check if authentication is supported
      if (_googleSignIn.supportsAuthenticate()) {
        await _googleSignIn.authenticate();
      } else {
        _showErrorDialog(
          'Error',
          'Google Sign-In is not supported on this platform',
        );
        setState(() => _isGoogleLoading = false);
      }
    } catch (error) {
      _onGoogleAuthenticationError(error);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authEventsSubscription?.cancel();
    super.dispose();
  }

  bool get _isIOS {
    return false;
  }

  bool get _isLoading => _loading || _isGoogleLoading;

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Error', 'Please fill in all fields');
      return;
    }

    setState(() => _loading = true);

    try {
      await ref
          .read(coreProvider.notifier)
          .emailSignIn(_emailController.text, _passwordController.text);
      final route = ref.read(coreProvider.notifier).getRoute();

      if (!mounted || route == '/login') return;

      Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
    } on FirebaseAuthException catch (e) {
      _showErrorDialog('Error', e.message ?? 'Authentication failed');
    } catch (e) {
      _showErrorDialog('Error', e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required String text,
    required Widget icon,
    required Color backgroundColor,
    required Color textColor,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed ?? () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          side: backgroundColor == Colors.white
              ? BorderSide(color: Colors.grey.shade300)
              : null,
        ),
        icon: icon,
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Text(
                      'SAUNOVA',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        letterSpacing: 6,
                        height: 1,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 100.ms)
                    .slideY(begin: -0.3, end: 0, curve: Curves.easeOutQuart),

                const SizedBox(height: 80),

                // Login form
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInQuart,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _showEmailLogin
                      ? _buildEmailLoginForm(colorScheme)
                      : _buildSocialLoginButtons(colorScheme),
                ),

                const SizedBox(height: 32),

                // Sign up link
                Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 900.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButtons(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('social'),
      children: [
        // Apple Sign In (iOS only)
        if (_isIOS) ...[
          _buildSocialLoginButton(
                text: 'Continue with Apple',
                icon: const Icon(Icons.apple, size: 24),
                backgroundColor: Colors.black,
                textColor: Colors.white,
                // onPressed: _handleAppleSignIn, // Implement if needed
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 700.ms)
              .slideX(begin: -0.2, end: 0, curve: Curves.easeOutQuart)
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
          const SizedBox(height: 16),
        ],

        // Google Sign In
        _buildSocialLoginButton(
              text: 'Continue with Google',
              icon: _isGoogleLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black87,
                        ),
                      ),
                    )
                  : Image.asset('assets/images/google.png', height: 24),
              backgroundColor: Colors.white,
              textColor: Colors.black87,
              onPressed: _isLoading ? null : _handleGoogleSignIn,
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: _isIOS ? 800.ms : 700.ms)
            .slideX(begin: -0.2, end: 0, curve: Curves.easeOutQuart)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

        const SizedBox(height: 24),

        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: colorScheme.outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: colorScheme.outline)),
          ],
        ).animate().fadeIn(duration: 500.ms, delay: 900.ms),

        const SizedBox(height: 24),

        // Email/Password button
        TextButton.icon(
              onPressed: () {
                setState(() => _showEmailLogin = true);
              },
              icon: const Icon(Icons.email_outlined, size: 20),
              label: const Text(
                'Continue with Email/Password',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: 1000.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuart),
      ],
    );
  }

  Widget _buildEmailLoginForm(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('email'),
      children: [
        // Email Input
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),

        const SizedBox(height: 16),

        // Password Input
        TextField(
          controller: _passwordController,
          obscureText: true,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: colorScheme.onSurfaceVariant,
            ),
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),

        const SizedBox(height: 24),

        // Sign In Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _loading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Back button
        TextButton.icon(
          onPressed: () {
            setState(() => _showEmailLogin = false);
          },
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to social login'),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
