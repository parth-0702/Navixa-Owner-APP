import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberSession = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.savedIdentifier != null && auth.savedIdentifier!.isNotEmpty) {
        _identifierController.text = auth.savedIdentifier!;
      }
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
      rememberSession: _rememberSession,
    );

    if (success && mounted) {
      context.go('/overview');
    }
  }

  void _autofillDemo(String email, String password) {
    _identifierController.text = email;
    _passwordController.text = password;
    context.read<AuthProvider>().clearError();
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text(
          'To reset your owner or manager credentials, please contact your platform administrator or email security@navixa.com.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPageBackground : AppColors.pageBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Header
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/navixa-icon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.local_shipping_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Welcome to Navixa',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to your fleet management dashboard',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Error Alert Banner
                    if (auth.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Identifier Field
                    Text('Email or Username', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        hintText: 'e.g. owner@navixa.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email or username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Password Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Password', style: theme.textTheme.labelMedium),
                        GestureDetector(
                          onTap: _showForgotPasswordDialog,
                          child: Text(
                            'Forgot password?',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.secondaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitLogin(),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Remember Session
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberSession,
                            activeColor: AppColors.primaryNavy,
                            onChanged: isLoading
                                ? null
                                : (v) => setState(() => _rememberSession = v ?? true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () => setState(() => _rememberSession = !_rememberSession),
                          child: Text('Remember my credentials', style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: isLoading ? null : _submitLogin,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sign In to Fleet'),
                    ),

                    // Biometric Unlock Option
                    if (auth.isBiometricAvailable && auth.isBiometricEnabled) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final router = GoRouter.of(context);
                                final success = await auth.authenticateWithBiometrics();
                                if (success && mounted) {
                                  router.go('/overview');
                                }
                              },
                        icon: const Icon(Icons.fingerprint_rounded, size: 20),
                        label: const Text('Sign in with Biometrics'),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Development Quick-Fill Chips
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.terminal_rounded, size: 16, color: AppColors.secondaryTeal),
                              SizedBox(width: 6),
                              Text(
                                'Quick Demo Credentials:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                label: const Text('Owner'),
                                avatar: const Icon(Icons.shield_rounded, size: 14),
                                onPressed: () => _autofillDemo('owner@navixa.com', 'ManagerPass123!'),
                              ),
                              ActionChip(
                                label: const Text('Manager'),
                                avatar: const Icon(Icons.person_rounded, size: 14),
                                onPressed: () => _autofillDemo('manager@navixa.com', 'ManagerPass123!'),
                              ),
                              ActionChip(
                                label: const Text('Viewer'),
                                avatar: const Icon(Icons.visibility_rounded, size: 14),
                                onPressed: () => _autofillDemo('viewer@navixa.com', 'ViewerPass123!'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
