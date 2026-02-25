import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/leaderboard_service.dart';
import '../widgets/lives_widget.dart';
import '../core/lives_service.dart';

class GlobalLeaderboardScreen extends StatefulWidget {
  const GlobalLeaderboardScreen({super.key});

  @override
  State<GlobalLeaderboardScreen> createState() =>
      _GlobalLeaderboardScreenState();
}

class _GlobalLeaderboardScreenState extends State<GlobalLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late LeaderboardService _leaderboardService;
  late LivesService _livesService;
  late TabController _tabController;

  List<Map<String, dynamic>> _globalLeaderboard = [];
  List<Map<String, dynamic>> _aroundMeLeaderboard = [];
  Map<String, dynamic>? _myRank;

  bool _isLoadingGlobal = true;
  bool _isLoadingAroundMe = false;
  String? _errorMessage;

  // Lives system
  int _currentLives = 3;
  int _maxLives = 3;
  DateTime? _nextRefillAt;

  @override
  void initState() {
    super.initState();
    _leaderboardService = LeaderboardService(baseUrl: ApiService.baseUrl);
    _livesService = LivesService(baseUrl: ApiService.baseUrl);
    _tabController = TabController(length: 2, vsync: this);

    _loadGlobalLeaderboard();
    _loadMyRank();
    _loadLives();

    _tabController.addListener(() {
      if (_tabController.index == 1 && _aroundMeLeaderboard.isEmpty) {
        _loadLeaderboardAroundMe();
      }
    });
  }

  Future<void> _loadLives() async {
    try {
      final token = ApiService.getToken();
      if (token != null) {
        final status = await _livesService.getLivesStatus(token);
        if (mounted) {
          setState(() {
            _currentLives = status['lives'] ?? 3;
            _maxLives = 3;
            _nextRefillAt = status['nextRefillAt'] != null
                ? DateTime.parse(status['nextRefillAt'].toString())
                : null;
          });
        }
      }
    } catch (e) {
      print('Error loading lives: $e');
    }
  }

  Future<void> _loadGlobalLeaderboard() async {
    setState(() {
      _isLoadingGlobal = true;
      _errorMessage = null;
    });

    try {
      final leaderboard = await _leaderboardService.getGlobalLeaderboard();
      if (mounted) {
        setState(() {
          _globalLeaderboard = leaderboard;
          _isLoadingGlobal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar el ranking';
          _isLoadingGlobal = false;
        });
      }
    }
  }

  Future<void> _loadMyRank() async {
    try {
      final token = ApiService.getToken();
      if (token == null) return;

      final rank = await _leaderboardService.getMyRank(token);
      if (mounted) {
        setState(() {
          _myRank = rank;
        });
      }
    } catch (e) {
      print('Error loading my rank: $e');
    }
  }

  Future<void> _loadLeaderboardAroundMe() async {
    setState(() => _isLoadingAroundMe = true);

    try {
      final token = ApiService.getToken();
      if (token == null) {
        setState(() => _isLoadingAroundMe = false);
        return;
      }

      final leaderboard = await _leaderboardService.getLeaderboardAroundMe(
        token,
      );
      if (mounted) {
        setState(() {
          _aroundMeLeaderboard = leaderboard;
          _isLoadingAroundMe = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAroundMe = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildMedalIcon(int rank) {
    switch (rank) {
      case 1:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.yellow.shade600, Colors.yellow.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.shade700.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
        );
      case 2:
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.grey.shade300, Colors.grey.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.emoji_events, color: Colors.white, size: 22),
        );
      case 3:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade400.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.emoji_events, color: Colors.white, size: 20),
        );
      default:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildLeaderboardTile(Map<String, dynamic> entry) {
    final rank = entry['rank'] ?? 0;
    final username = entry['username'] ?? 'Usuario';
    final totalXP = entry['totalXP'] ?? 0;
    final level = entry['level'] ?? 1;
    final isCurrentUser = entry['isCurrentUser'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? Colors.orange.shade300 : Colors.grey.shade200,
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank / Medal
          _buildMedalIcon(rank),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isCurrentUser
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isCurrentUser
                              ? Colors.orange.shade800
                              : Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TÚ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Nivel $level',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade600, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$totalXP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              Text(
                'XP',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankCard() {
    if (_myRank == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade300.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu Posición',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '#${_myRank!['rank']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${_myRank!['totalXP']} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Top ${_myRank!['percentile']}%',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ranking Mundial',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        ),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Top 30'),
            Tab(text: 'A tu alrededor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Global Top 30
          _isLoadingGlobal
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                )
              : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadGlobalLeaderboard,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGlobalLeaderboard,
                  child: ListView(
                    children: [
                      if (_myRank != null) _buildMyRankCard(),
                      const SizedBox(height: 8),
                      ..._globalLeaderboard.map(_buildLeaderboardTile),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

          // Around Me
          _isLoadingAroundMe
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                )
              : _aroundMeLeaderboard.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Inicia sesión para ver tu ranking',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLeaderboardAroundMe,
                  child: ListView(
                    children: [
                      if (_myRank != null) _buildMyRankCard(),
                      const SizedBox(height: 8),
                      ..._aroundMeLeaderboard.map(_buildLeaderboardTile),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
