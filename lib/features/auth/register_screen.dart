import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_selection_provider.dart';
import '../../core/api_service.dart';
import '../learning/screens/follow_goals_screen.dart';
import '../learning/screens/country_hub_screen.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthProvider>().register(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        await _navigateAfterRegistration();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateAfterRegistration() async {
    final selectionProvider = context.read<OnboardingSelectionProvider>();
    await selectionProvider.loadSelection();

    if (!mounted) return;

    if (selectionProvider.hasSelection()) {
      final mode = selectionProvider.mode;
      final selectionId = selectionProvider.selectionId;
      final selectionName = selectionProvider.selectionName;

      // Limpiar la selección después de usarla
      await selectionProvider.clearSelection();

      if (mode == 'goals' && selectionId != null) {
        // Navegar a FollowGoalsScreen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/goals');
        }
      } else if (mode == 'countries' && selectionId != null) {
        // Navegar a CountryHubScreen con el país seleccionado
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CountryHubScreen(
                countryId: selectionId,
                countryName: selectionName,
                countryIcon: '🌍',
              ),
            ),
          );
        }
      } else {
        // Sin selección, ir a la pantalla principal
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      }
    } else {
      // Sin selección, ir a la pantalla principal
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Integrar con Google Sign-In cuando esté disponible
      // Por ahora, mostrar un mensaje de que está en desarrollo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Funcionalidad próximamente'),
          backgroundColor: const Color(0xFFFF6B35),
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Stack(
          children: [
            // Botón de volver minimalista
            Positioned(
              top: 16,
              left: 16,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // Contenido principal
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
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
                          const SizedBox(height: 20),

                          // Logo con animación
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: const Text(
                              "🍳",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 90),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Título
                          Text(
                            "Únete a Cappy",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtítulo
                          Text(
                            "Comienza tu aventura culinaria",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 48),

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
                                  helperText: "Mínimo 6 caracteres",
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Ingresa tu contraseña";
                                    }
                                    if (value.length < 6) {
                                      return "La contraseña debe tener al menos 6 caracteres";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Confirmar Password
                                AuthTextField(
                                  controller: _confirmPasswordController,
                                  labelText: "Confirmar Contraseña",
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Confirma tu contraseña";
                                    }
                                    if (value != _passwordController.text) {
                                      return "Las contraseñas no coinciden";
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

                                // Botón de registro
                                PrimaryButton(
                                  text: "Registrarse",
                                  onPressed: _isLoading
                                      ? null
                                      : _handleRegister,
                                  isLoading: _isLoading,
                                ),

                                const SizedBox(height: 20),

                                // Divisor
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        "o",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: const Color(0xFF9CA3AF),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Google Sign-In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleGoogleSignIn,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          '🔐',
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Registrarse con Google",
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Link de login
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
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
                                  const TextSpan(text: "¿Ya tienes cuenta? "),
                                  TextSpan(
                                    text: "Inicia sesión",
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
          ],
        ),
      ),
    );
  }
}
