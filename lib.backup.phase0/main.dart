import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/onboarding_intro_screen.dart';
import 'features/auth/onboarding_mode_selection_screen.dart';
import 'features/auth/onboarding_goals_screen.dart';
import 'features/auth/onboarding_countries_screen.dart';
import 'features/learning/screens/main_experience_screen.dart';
import 'features/learning/screens/country_selection_screen.dart';
import 'features/learning/screens/country_hub_screen.dart';
import 'features/learning/screens/follow_goals_screen.dart';
import 'features/lessons/lesson_detail_screen.dart';
import 'features/pantry/pantry_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/admin_v2/layout/admin_shell_modern.dart';
import 'providers/auth_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/onboarding_selection_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CappyApp());
}

class CappyApp extends StatelessWidget {
  const CappyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingSelectionProvider()),
      ],
      child: MaterialApp(
        title: 'Cappy - Cocina feliz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }
}

/// ==============================
/// SPLASH SCREEN
/// ==============================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AuthProvider? _authProvider;
  bool _hasListener = false;

  @override
  void initState() {
    super.initState();
    // Escucha los cambios del AuthProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      _authProvider = authProvider;
      if (!_hasListener) {
        authProvider.addListener(_onAuthStatusChanged);
        _hasListener = true;
      }
      // Si ya terminó de inicializar, navega inmediatamente
      if (!authProvider.isInitializing) {
        _navigate(authProvider);
      }
    });
  }

  void _onAuthStatusChanged() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isInitializing) {
      _navigate(authProvider);
    }
  }

  void _navigate(AuthProvider authProvider) {
    if (!mounted) return;
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  void dispose() {
    if (_hasListener) {
      _authProvider?.removeListener(_onAuthStatusChanged);
      _hasListener = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E6),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Image.asset('assets/logo_cappy.png', width: 150, height: 150),
            const SizedBox(height: 20),
            // Eslogan
            const Text(
              "Cocina feliz",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 40),
            // Loading
            const CircularProgressIndicator(color: Colors.orange),
          ],
        ),
      ),
    );
  }
}

/// ==============================
/// ROUTES
/// ==============================
Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      final authProvider = context.watch<AuthProvider>();

      // Si todavía inicializa, mostrar splash
      if (authProvider.isInitializing) {
        return const SplashScreen();
      }

      final name = settings.name ?? "/";

      // Auth routes (accesibles sin autenticarse)
      if (name == "/welcome") return const WelcomeScreen();
      if (name == "/login") return const LoginScreen();
      if (name == "/register") return const RegisterScreen();
      if (name == "/onboarding/intro") return const OnboardingIntroScreen();
      if (name == "/onboarding/mode") {
        return const OnboardingModeSelectionScreen();
      }
      if (name == "/onboarding/goals") return const OnboardingGoalsScreen();
      if (name == "/onboarding/countries") {
        return const OnboardingCountriesScreen();
      }

      // Si no está autenticado, redirigir a welcome
      if (!authProvider.isAuthenticated) return const WelcomeScreen();

      // Main routes (requieren autenticación)
      if (name == "/" || name == "/main" || name == "/experience") {
        return const MainExperienceScreen();
      }

      if (name == "/experience/countries") {
        return const CountrySelectionScreen();
      }

      if (name == "/goals") {
        return const FollowGoalsScreen(isModal: true);
      }

      // Router dinámico para mode selection
      if (name == "/paths") {
        final args = settings.arguments as Map?;
        final type = args?['type'] as String?;

        if (type == "country") {
          return const CountrySelectionScreen();
        } else if (type == "goal") {
          return const FollowGoalsScreen(isModal: true);
        }
        // Fallback si no hay type válido
        return const MainExperienceScreen();
      }

      if (name == "/pantry") return const PantryScreen();
      if (name == "/profile") return const ProfileScreen();
      if (name == "/admin" || name == "/admin-v2") {
        if (!authProvider.isAdmin) {
          return const MainExperienceScreen();
        }

        final args = settings.arguments is Map
            ? settings.arguments as Map
            : const {};
        return AdminShellModern(
          initialPathId: args['pathId']?.toString(),
          initialNodeId: args['nodeId']?.toString(),
        );
      }

      // Dynamic routes
      if (name.startsWith("/experience/country/")) {
        final countryId = name.split('/').last;
        return CountryHubScreen(countryId: countryId);
      }

      if (name.startsWith("/lesson/")) return LessonDetailScreen();

      // Default fallback
      return const MainExperienceScreen();
    },
  );
}
