import 'dart:async';

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
import 'features/learning/screens/recipe_detail_screen.dart';
import 'features/learning/screens/recipes_list_screen.dart';
import 'features/lessons/lesson_detail_screen.dart';
import 'features/pantry/pantry_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/admin_v2/layout/admin_shell_modern.dart';
import 'core/image_optimize_service.dart';
import 'core/audio_feedback_service.dart';
import 'providers/auth_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/onboarding_selection_provider.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initializeFromDartDefine();

  // Inicializar servicio de audio con pre-caché
  await AudioFeedbackService().initialize();

  final authProvider = AuthProvider();

  await Future.wait([authProvider.initialize()]);

  runApp(CappyApp(authProvider: authProvider));
}

class CappyApp extends StatefulWidget {
  final AuthProvider authProvider;

  const CappyApp({super.key, required this.authProvider});

  @override
  State<CappyApp> createState() => _CappyAppState();
}

class _CappyAppState extends State<CappyApp> {
  @override
  void initState() {
    super.initState();
    // Doble seguridad: el servicio es idempotente y evita latencia por init tardio.
    unawaited(AudioFeedbackService().initialize());
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: widget.authProvider),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingSelectionProvider()),
      ],
      child: MaterialApp(
        title: 'Cappy - Cocina feliz',
        debugShowCheckedModeBanner: AppConfig.showDebugBanner,
        theme: AppTheme.lightTheme,
        home: widget.authProvider.isAuthenticated
            ? const MainExperienceScreen()
            : const WelcomeScreen(),
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
      backgroundColor: AppColors.background,
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
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 40),
            // Loading
            const CircularProgressIndicator(color: AppColors.primary),
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
      final auth = context.read<AuthProvider>();
      final authState = (
        isInitializing: auth.isInitializing,
        isAuthenticated: auth.isAuthenticated,
        isAdmin: auth.isAdmin,
      );

      // Si todavía inicializa, mostrar splash
      if (authState.isInitializing) {
        return const SplashScreen();
      }

      final name = settings.name ?? "/";

      _scheduleRoutePrewarm(context, name, settings.arguments);

      const publicAuthRoutes = {
        '/welcome',
        '/login',
        '/register',
        '/onboarding/intro',
        '/onboarding/mode',
        '/onboarding/goals',
        '/onboarding/countries',
      };

      if (authState.isAuthenticated && publicAuthRoutes.contains(name)) {
        return const MainExperienceScreen();
      }

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
      if (!authState.isAuthenticated) return const WelcomeScreen();

      // Main routes (requieren autenticación)
      if (name == "/" || name == "/main" || name == "/experience") {
        return const MainExperienceScreen();
      }

      if (name == "/experience/countries") {
        return const CountrySelectionScreen();
      }

      if (name == '/experience/recipes') {
        final args = settings.arguments is Map
            ? Map<String, dynamic>.from(settings.arguments as Map)
            : <String, dynamic>{};

        return RecipesListScreen(
          countryId: args['countryId']?.toString() ?? '',
          pathId: args['pathId']?.toString() ?? '',
          pathTitle: args['pathTitle']?.toString() ?? 'Recetas',
          countryName: args['countryName']?.toString() ?? 'Pais',
        );
      }

      if (name.startsWith('/experience/recipe/')) {
        final recipeId = name.split('/').last;
        final args = settings.arguments is Map
            ? Map<String, dynamic>.from(settings.arguments as Map)
            : <String, dynamic>{};

        return RecipeDetailScreen(
          recipeId: recipeId,
          recipeTitle: args['recipeTitle']?.toString() ?? 'Receta',
        );
      }

      if (name == "/goals") {
        return const FollowGoalsScreen();
      }

      if (name == "/pantry") return const PantryScreen();
      if (name == "/profile") return const ProfileScreen();
      if (name == "/admin" || name == "/admin-v2") {
        if (!authState.isAdmin) {
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
        final args = settings.arguments is Map
            ? Map<String, dynamic>.from(settings.arguments as Map)
            : <String, dynamic>{};

        return CountryHubScreen(
          countryId: countryId,
          countryName: args['countryName']?.toString(),
          countryIcon: args['countryIcon']?.toString(),
          heroTag: args['heroTag']?.toString(),
        );
      }

      if (name.startsWith("/lesson/")) return LessonDetailScreen();

      // Default fallback
      return const MainExperienceScreen();
    },
  );
}

void _scheduleRoutePrewarm(
  BuildContext context,
  String routeName,
  Object? arguments,
) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    unawaited(
      ImageOptimizeService.prewarmRouteImages(
        context: context,
        routeName: routeName,
        arguments: arguments,
      ),
    );
  });
}
