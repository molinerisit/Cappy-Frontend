import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api_service.dart';
import 'country_hub_screen.dart';

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
          // Header section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Qué cocina quieres explorar?',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Descubre recetas auténticas y cultura culinaria',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Countries grid
          Expanded(
            child: Stack(
              children: [
                GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    final countryId = country['_id'] ?? country['id'] ?? '';
                    final countryName = country['name'] ?? 'País';
                    final countryIcon = country['icon'] ?? '🌍';
                    final countryColor = _getCountryColor(index);

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 400 + (index * 80)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: _CountryCard(
                        countryId: countryId,
                        countryName: countryName,
                        countryIcon: countryIcon,
                        accentColor: countryColor,
                      ),
                    );
                  },
                ),
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

class _CountryCard extends StatefulWidget {
  final String countryId;
  final String countryName;
  final String countryIcon;
  final Color accentColor;

  const _CountryCard({
    required this.countryId,
    required this.countryName,
    required this.countryIcon,
    required this.accentColor,
  });

  @override
  State<_CountryCard> createState() => _CountryCardState();
}

class _CountryCardState extends State<_CountryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CountryHubScreen(countryId: widget.countryId),
          ),
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono circular con color de fondo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.countryIcon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Nombre del país
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  widget.countryName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Badge "Explorar"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: widget.accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Explorar',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
