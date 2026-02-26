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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap: inicializar providers antes de runApp
  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(CappyApp(authProvider: authProvider));
}

class CappyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const CappyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingSelectionProvider()),
      ],
      child: MaterialApp(
        title: 'Cappy - Cocina feliz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: authProvider.isAuthenticated
            ? const MainExperienceScreen()
            : const WelcomeScreen(),
        onGenerateRoute: _onGenerateRoute,
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
