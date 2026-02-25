import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cooklevel_app/core/lives_service.dart';
import 'package:cooklevel_app/widgets/lives_widget.dart';

class NoLivesScreen extends StatefulWidget {
  final String token;
  final String baseUrl;
  final VoidCallback? onLivesRestored;

  const NoLivesScreen({
    super.key,
    required this.token,
    required this.baseUrl,
    this.onLivesRestored,
  });

  @override
  State<NoLivesScreen> createState() => _NoLivesScreenState();
}

class _NoLivesScreenState extends State<NoLivesScreen> {
  late LivesService _livesService;
  late Timer _checkTimer;
  DateTime? _nextRefillAt;
  Duration? _timeRemaining;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _livesService = LivesService(baseUrl: widget.baseUrl);
    _loadInitialData();
    _startCheckTimer();
  }

  Future<void> _loadInitialData() async {
    try {
      final status = await _livesService.getLivesStatus(widget.token);
      if (mounted) {
        setState(() {
          _nextRefillAt = status['nextRefillAt'] != null
              ? DateTime.parse(status['nextRefillAt'])
              : null;
          _isLoading = false;
          _updateTimeRemaining();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startCheckTimer() {
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      _updateTimeRemaining();

      // Check if vidas were refilled
      if (_timeRemaining != null && _timeRemaining!.isNegative) {
        final canStart = await _livesService.canStartLesson(widget.token);
        if (canStart && mounted) {
          widget.onLivesRestored?.call();
          Navigator.pop(context, true);
        }
      }
    });
  }

  void _updateTimeRemaining() {
    if (_nextRefillAt != null) {
      final now = DateTime.now();
      final difference = _nextRefillAt!.difference(now);

      setState(() {
        _timeRemaining = difference.isNegative ? Duration.zero : difference;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  void dispose() {
    _checkTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Empty hearts animation
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.favorite_border,
                          size: 60,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      '¡Sin vidas disponibles!',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Text(
                      'Necesitas al menos una vida para continuar aprendiendo. Las vidas se recuperan automáticamente cada 2 horas.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Time until next life
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.orange,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Próxima vida en:',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_timeRemaining != null)
                            Text(
                              _formatDuration(_timeRemaining!),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            )
                          else
                            const Text(
                              '--:--',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cada lección tiene un máximo de 3 intentos. Cuida tus vidas.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                              ),
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
