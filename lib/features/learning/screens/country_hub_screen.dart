import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import '../../../core/models/learning_path.dart';
import '../widgets/country_locked_view.dart';
import '../widgets/learning_empty_view.dart';
import 'recipes_list_screen.dart';

class CountryHubScreen extends StatefulWidget {
  final String countryId;
  final String? countryName;
  final String? countryIcon;
  final String? heroTag;

  const CountryHubScreen({
    super.key,
    required this.countryId,
    this.countryName,
    this.countryIcon,
    this.heroTag,
  });

  @override
  State<CountryHubScreen> createState() => _CountryHubScreenState();
}

class _CountryHubScreenState extends State<CountryHubScreen> {
  late Future<CountryHub> futureCountryHub;

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _surface = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    futureCountryHub = _loadCountryHub();
  }

  Future<CountryHub> _loadCountryHub() async {
    final data = await ApiService.getCountryHub(widget.countryId);
    return CountryHub.fromJson(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Text('${widget.countryName ?? 'País'}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: FutureBuilder<CountryHub>(
        future: futureCountryHub,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryBlue),
            );
          } else if (snapshot.hasError) {
            return CountryLockedView(
              error: snapshot.error!,
              onBack: () => Navigator.of(context).pop(),
              onRetry: () {
                setState(() {
                  futureCountryHub = _loadCountryHub();
                });
              },
            );
          } else if (!snapshot.hasData) {
            return LearningEmptyView(
              emoji: '🌍',
              title: 'No hay datos disponibles',
              description:
                  'No pudimos encontrar contenido para este país en este momento.',
              onBack: () => Navigator.of(context).pop(),
            );
          }

          final hub = snapshot.data!;
          final summary =
              hub.presentationSummary ??
              hub.description ??
              'Explora recetas guiadas, técnicas clave y una experiencia de cocina estructurada.';
          final headline =
              hub.presentationHeadline ??
              'Bienvenido a la cocina de ${hub.name}';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _CountryHeaderCard(
                heroTag: widget.heroTag ?? 'country-flag-${widget.countryId}',
                countryIcon: widget.countryIcon ?? hub.icon,
                countryName: widget.countryName ?? hub.name,
                headline: headline,
                summary: summary,
                heroImageUrl: hub.heroImageUrl,
                iconicDishes: hub.iconicDishes,
              ),
              const SizedBox(height: 16),
              _PathCard(
                path: hub.recipes,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RecipesListScreen(
                        countryId: widget.countryId,
                        pathId: hub.recipes.id,
                        pathTitle: hub.recipes.title,
                        countryName: widget.countryName ?? hub.name,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CountryHeaderCard extends StatelessWidget {
  final String heroTag;
  final String countryIcon;
  final String countryName;
  final String headline;
  final String summary;
  final String? heroImageUrl;
  final List<String> iconicDishes;

  const _CountryHeaderCard({
    required this.heroTag,
    required this.countryIcon,
    required this.countryName,
    required this.headline,
    required this.summary,
    required this.heroImageUrl,
    required this.iconicDishes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (heroImageUrl != null && heroImageUrl!.trim().isNotEmpty)
                    Image.network(
                      heroImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradientFallback(),
                    )
                  else
                    _gradientFallback(),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0x880F172A), Color(0x000F172A)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    child: Row(
                      children: [
                        Hero(
                          tag: heroTag,
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              countryIcon,
                              style: const TextStyle(fontSize: 34),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          countryName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summary,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Color(0xFF475569),
                  ),
                ),
                if (iconicDishes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: iconicDishes
                        .take(4)
                        .map(
                          (dish) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: Text(
                              dish,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1D4ED8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF10B981)],
        ),
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
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(path.icon, style: const TextStyle(fontSize: 40)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${path.nodes.length} pasos',
                          style: const TextStyle(
                            color: Color(0xFF1D4ED8),
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
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                path.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
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
                    color: Color(0xFF1D4ED8),
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
      'fácil': const Color(0xFF10B981),
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
