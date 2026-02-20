import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, "/mode");
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleLogin() async {
    // TODO: Implementar Google Sign-In cuando esté listo el backend
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Login con Google próximamente disponible',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF3B82F6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo con animación
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: const Text(
                          "🍳",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 100),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Título
                      Text(
                        "Cappy",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtítulo
                      Text(
                        "Cocina feliz",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 56),

                      // Card con formulario
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Email
                            AuthTextField(
                              controller: _emailController,
                              labelText: "Email",
                              icon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Ingresa tu email";
                                }
                                if (!value.contains('@')) {
                                  return "Email inválido";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password
                            AuthTextField(
                              controller: _passwordController,
                              labelText: "Contraseña",
                              icon: Icons.lock_rounded,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Ingresa tu contraseña";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Error message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFECACA),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFB91C1C),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Botón de login
                            PrimaryButton(
                              text: "Iniciar Sesión",
                              onPressed: _isLoading ? null : _handleLogin,
                              isLoading: _isLoading,
                            ),

                            const SizedBox(height: 24),

                            // Divider con texto
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'O continúa con',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFF9CA3AF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Botón de Google
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleGoogleLogin,
                              icon: Image.asset(
                                'assets/google_logo.png',
                                height: 24,
                                width: 24,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback a emoji si no hay imagen
                                  return const Text(
                                    '🔍',
                                    style: TextStyle(fontSize: 20),
                                  );
                                },
                              ),
                              label: Text(
                                'Continuar con Google',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Link de registro
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, "/register");
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: const Color(0xFF6B7280),
                            ),
                            children: [
                              const TextSpan(text: "¿No tienes cuenta? "),
                              TextSpan(
                                text: "Regístrate",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF27AE60),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
