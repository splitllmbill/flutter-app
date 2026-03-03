import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showForgotPassword = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final apiClient = ref.read(apiClientProvider);

      if (_showForgotPassword) {
        await authService.sendPasswordResetEmail(_emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent! Check your inbox.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          setState(() => _showForgotPassword = false);
        }
      } else if (_isLogin) {
        await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Register with backend
        try {
          await apiClient.post('/db/login', data: {
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          });
        } catch (_) {
          // Backend registration optional during migration
        }
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() => _errorMessage = 'Passwords do not match');
          return;
        }

        await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );

        // Register with backend
        try {
          await apiClient.post('/db/signup', data: {
            'email': _emailController.text.trim(),
            'name': _nameController.text.trim(),
            'password': _passwordController.text,
          });
        } catch (_) {
          // Backend registration optional during migration
        }
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
    } on Exception catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(Exception e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('user-not-found'))
      return 'No account found with this email';
    if (msg.contains('wrong-password')) return 'Incorrect password';
    if (msg.contains('email-already-in-use')) return 'Email already registered';
    if (msg.contains('weak-password')) return 'Password is too weak';
    if (msg.contains('invalid-email')) return 'Invalid email address';
    if (msg.contains('cancelled')) return 'Sign-in cancelled';
    if (msg.contains('network')) return 'Network error. Check your connection.';
    return 'An error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0D1A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: isWide ? _buildWideLayout(size) : _buildNarrowLayout(size),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left: Branding
        SizedBox(
          width: 400,
          child: _buildBranding(),
        ),
        const SizedBox(width: 80),
        // Right: Form
        SizedBox(
          width: 420,
          child: _buildFormCard(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(Size size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBrandingCompact(),
        const SizedBox(height: 32),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _buildFormCard(),
        ),
      ],
    );
  }

  Widget _buildBranding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.receipt_long_rounded,
              color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        const Text(
          'SplitLLM',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Split bills smartly with AI.\nTrack expenses, settle dues, stay balanced.',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.6),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingCompact() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.receipt_long_rounded,
              color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text(
          'SplitLLM',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _showForgotPassword
                  ? 'Reset Password'
                  : _isLogin
                      ? 'Welcome Back'
                      : 'Create Account',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showForgotPassword
                  ? 'Enter your email to receive a reset link'
                  : _isLogin
                      ? 'Sign in to continue'
                      : 'Sign up to get started',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: AppTheme.errorColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Name field (sign up only)
            if (!_isLogin && !_showForgotPassword) ...[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
            ],

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),

            // Password fields (not for forgot password)
            if (!_showForgotPassword) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),

              // Confirm password (sign up only)
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ],

            // Forgot password link
            if (_isLogin && !_showForgotPassword) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _showForgotPassword = true),
                  child: const Text('Forgot Password?'),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _showForgotPassword
                            ? 'Send Reset Link'
                            : _isLogin
                                ? 'Sign In'
                                : 'Create Account',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            // Google sign in
            if (!_showForgotPassword) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.white.withOpacity(0.15)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.white.withOpacity(0.15)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Toggle login/signup
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _showForgotPassword
                      ? 'Remember your password?'
                      : _isLogin
                          ? "Don't have an account?"
                          : 'Already have an account?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_showForgotPassword) {
                        _showForgotPassword = false;
                      } else {
                        _isLogin = !_isLogin;
                      }
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    _showForgotPassword
                        ? 'Sign In'
                        : _isLogin
                            ? 'Sign Up'
                            : 'Sign In',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
