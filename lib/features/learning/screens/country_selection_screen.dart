import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api_service.dart';
import 'country_hub_screen.dart';
import '../widgets/country_selection_card.dart';

class CountrySelectionScreen extends StatefulWidget {
  const CountrySelectionScreen({super.key});

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 20;
  final List<dynamic> _countries = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  String? _errorMessage;
  DateTime? _lastLoadMoreAt;
  static const Duration _loadMoreCooldown = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialCountries();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  Future<void> _loadInitialCountries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _countries.clear();
      _currentPage = 1;
    });

    await _fetchCountriesPage(page: 1, append: false);
  }

  Future<void> _loadMoreCountries() async {
    if (_isLoadingMore || !_hasMore) return;
    final now = DateTime.now();
    if (_lastLoadMoreAt != null &&
        now.difference(_lastLoadMoreAt!) < _loadMoreCooldown) {
      return;
    }
    _lastLoadMoreAt = now;

    setState(() => _isLoadingMore = true);
    await _fetchCountriesPage(page: _currentPage + 1, append: true);
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasMore) return;
    if (_isLoading || _isLoadingMore) return;

    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;

    final triggerOffset = position.maxScrollExtent * 0.8;
    if (position.pixels >= triggerOffset) {
      _loadMoreCountries();
    }
  }

  String? _extractEntityId(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      final id = raw['_id'] ?? raw['id'] ?? raw['\$oid'];
      if (id == null) return null;
      return _extractEntityId(id);
    }

    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  List<dynamic> _dedupeByEntityId(List<dynamic> source) {
    final unique = <dynamic>[];
    final seen = <String>{};

    for (final item in source) {
      final id = _extractEntityId(item);
      final key = id ?? '__fallback_${item.hashCode}_${unique.length}';
      if (seen.add(key)) {
        unique.add(item);
      }
    }

    return unique;
  }

  Future<void> _fetchCountriesPage({
    required int page,
    required bool append,
  }) async {
    final stopwatch = Stopwatch()..start();
    int fetchedCount = 0;
    bool hasMore = false;
    String status = 'ok';

    try {
      final response = await ApiService.getCountriesPaginated(
        page: page,
        limit: _pageSize,
      );

      final items = response['data'] as List<dynamic>? ?? <dynamic>[];
      final pagination = response['pagination'] as Map<String, dynamic>?;
      hasMore = pagination?['hasMore'] == true;
      fetchedCount = items.length;

      setState(() {
        _currentPage = page;
        _hasMore = hasMore;
        final merged = append
            ? <dynamic>[..._countries, ...items]
            : <dynamic>[...items];
        _countries
          ..clear()
          ..addAll(_dedupeByEntityId(merged));
      });
    } catch (e) {
      status = 'error';
      if (!append) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint(
          '[Pagination][Countries] page=$page append=$append fetched=$fetchedCount hasMore=$hasMore status=$status ms=${stopwatch.elapsedMilliseconds}',
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          color: const Color(0xFF6B7280),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        title: Text(
          'Experiencia Culinaria',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_countries.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildHeaderSection(),

          Expanded(
            child: Stack(
              children: [
                _buildCountriesGrid(),
                if (_hasMore)
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: ElevatedButton(
                      onPressed: _isLoadingMore ? null : _loadMoreCountries,
                      child: _isLoadingMore
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Cargar más'),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: IgnorePointer(
                    ignoring: true,
                    child: AnimatedOpacity(
                      opacity: _isLoadingMore ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Color(0xFFFF6B35),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Tu viaje culinario',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '¿Qué cocina quieres explorar?',
            style: GoogleFonts.poppins(
              fontSize: 33,
              height: 1.12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Empieza con un país y descubre sabores auténticos paso a paso.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.45,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountriesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 20.0;
        const spacing = 16.0;
        const minCardWidth = 140.0;

        final usableWidth = constraints.maxWidth - (horizontalPadding * 2);
        final computedCount = (usableWidth / minCardWidth).floor();
        final crossAxisCount = computedCount.clamp(1, 4);
        final cardWidth =
            (usableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        final cardHeight = crossAxisCount == 1
            ? cardWidth * 0.66
            : cardWidth * 1.14;
        final childAspectRatio = cardWidth / cardHeight;

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(horizontalPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: _countries.length,
          itemBuilder: (context, index) {
            final country = _CountryListItem.fromJson(
              _countries[index],
              fallbackColor: _getCountryColor(index),
            );

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 260 + (index * 35)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - value) * 18),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: CountrySelectionCard(
                countryName: country.name,
                countryIcon: country.icon,
                accentColor: country.color,
                heroTag: country.heroTag,
                isLocked: country.isLocked,
                lockLabel: country.lockLabel,
                onTap: () => _openCountry(country),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCountry(_CountryListItem country) async {
    if (country.isLocked) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(country.lockReason)));
      }
      return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) {
          return CountryHubScreen(
            countryId: country.id,
            countryName: country.name,
            countryIcon: country.icon,
            heroTag: country.heroTag,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Color _getCountryColor(int index) {
    final colors = [
      const Color(0xFF3B82F6), // Azul
      const Color(0xFF10B981), // Verde
      const Color(0xFFF59E0B), // Amarillo
      const Color(0xFFEF4444), // Rojo
      const Color(0xFF8B5CF6), // Púrpura
      const Color(0xFF06B6D4), // Cyan
    ];
    return colors[index % colors.length];
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar países',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta nuevamente más tarde',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _loadInitialCountries();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Reintentar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌍', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text(
              'Aún no hay países',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pronto agregaremos nuevas experiencias culinarias',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryListItem {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final bool isLocked;
  final String lockLabel;
  final String lockReason;

  const _CountryListItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isLocked,
    required this.lockLabel,
    required this.lockReason,
  });

  String get heroTag => 'country-flag-$id';

  factory _CountryListItem.fromJson(
    dynamic json, {
    required Color fallbackColor,
  }) {
    final unlock = json['unlock'] as Map<String, dynamic>?;
    final isUnlocked = unlock?['isUnlocked'] == true;
    final isLocked = unlock != null ? !isUnlocked : false;

    final unlockLevel = (unlock?['unlockLevel'] is num)
        ? (unlock?['unlockLevel'] as num).toInt()
        : 1;
    final missingGroups = (unlock?['missingGroupIds'] as List?)?.length ?? 0;

    String lockReason = 'País bloqueado por progresión';
    if (unlock != null) {
      final levelMet = unlock['levelMet'] == true;
      final groupsMet = unlock['groupsMet'] == true;
      if (!levelMet) {
        lockReason =
            'Necesitas llegar al nivel $unlockLevel para desbloquear este país';
      } else if (!groupsMet) {
        lockReason = missingGroups > 0
            ? 'Completa $missingGroups grupo(s) de nodos para desbloquear este país'
            : 'Completa los grupos requeridos para desbloquear este país';
      }
    }

    final lockLabel = isLocked
        ? (unlock != null && unlock['levelMet'] != true
              ? 'Nivel $unlockLevel requerido'
              : 'Completa grupos')
        : 'Disponible';

    return _CountryListItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? 'País').toString(),
      icon: (json['icon'] ?? '🌍').toString(),
      color: fallbackColor,
      isLocked: isLocked,
      lockLabel: lockLabel,
      lockReason: lockReason,
    );
  }
}
