import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/lives_service.dart';
import '../core/models/learning_path.dart';
import '../widgets/lives_widget.dart';
import '../features/learning/screens/recipes_list_screen.dart';

class CountryHubScreen extends StatefulWidget {
  final String countryId;
  final String? countryName;
  final String? countryIcon;

  const CountryHubScreen({
    super.key,
    required this.countryId,
    this.countryName,
    this.countryIcon,
  });

  @override
  State<CountryHubScreen> createState() => _CountryHubScreenState();
}

class _CountryHubScreenState extends State<CountryHubScreen> {
  late Future<CountryHub> futureCountryHub;

  // Lives system
  late LivesService _livesService;
  int _currentLives = 3;
  int _maxLives = 3;
  DateTime? _nextRefillAt;
  bool _livesLoaded = false;

  @override
  void initState() {
    super.initState();
    futureCountryHub = _loadCountryHub();
    _initializeLives();
  }

  void _initializeLives() {
    _livesService = LivesService(baseUrl: ApiService.baseUrl);
    _loadLives();
  }

  Future<void> _loadLives() async {
    try {
      final token = ApiService.getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _currentLives = 3;
            _maxLives = 3;
            _nextRefillAt = null;
            _livesLoaded = true;
          });
        }
        return;
      }

      final status = await _livesService.getLivesStatus(token);

      if (mounted) {
        setState(() {
          _currentLives = status['lives'] ?? 3;
          _maxLives = 3;
          _nextRefillAt = status['nextRefillAt'] != null
              ? DateTime.parse(status['nextRefillAt'].toString())
              : null;
          _livesLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading lives: $e');
      if (mounted) {
        setState(() {
          _currentLives = 3;
          _maxLives = 3;
          _nextRefillAt = null;
          _livesLoaded = true;
        });
      }
    }
  }

  Future<CountryHub> _loadCountryHub() async {
    final data = await ApiService.getCountryHub(widget.countryId);
    return CountryHub.fromJson(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.countryIcon ?? '🌍'} ${widget.countryName ?? 'País'}',
        ),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: LivesWidget(
                lives: _currentLives,
                maxLives: _maxLives,
                nextRefillAt: _nextRefillAt,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<CountryHub>(
        future: futureCountryHub,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFFF6B35),
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        futureCountryHub = _loadCountryHub();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No hay datos disponibles'));
          }

          final hub = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFF6B35).withOpacity(0.1),
                        const Color(0xFFFFA500).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.countryIcon ?? '🌍',
                        style: const TextStyle(fontSize: 80),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.countryName ?? 'País',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      if (hub.description != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          hub.description!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _PathCard(
                        path: hub.recipes,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RecipesListScreen(
                                countryId: widget.countryId,
                                pathId: hub.recipes.id,
                                pathTitle: hub.recipes.title,
                                countryName: widget.countryName ?? 'País',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final LearningPath path;
  final VoidCallback onTap;

  const _PathCard({required this.path, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: path.isCountryRecipe
                  ? [
                      const Color(0xFFFF6B35).withOpacity(0.9),
                      const Color(0xFFFFA500).withOpacity(0.9),
                    ]
                  : [
                      const Color(0xFF4CAF50).withOpacity(0.9),
                      const Color(0xFF45a049).withOpacity(0.9),
                    ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(path.icon, style: const TextStyle(fontSize: 48)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${path.nodes.length} pasos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                path.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                path.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (path.metadata != null &&
                      path.metadata!['difficulty'] != null)
                    _DifficultyBadge(difficulty: path.metadata!['difficulty']),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'fácil': const Color(0xFF4CAF50),
      'medio': const Color(0xFFFFC107),
      'difícil': const Color(0xFFF44336),
    };

    final color = colors[difficulty.toLowerCase()] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
