import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/earth_planet_widget.dart';
import '../core/api_service.dart';
import '../core/countries_service.dart';

/// Pantalla fullscreen secuencial para ejecución de recetas.
class CookingModeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> steps;
  final Function(int) onStepComplete;
  final String? recipeName;
  final String? countryName;
  final String? countryFlag;
  final String? countryId;
  final int xpReward;

  const CookingModeScreen({
    required this.steps,
    required this.onStepComplete,
    this.recipeName,
    this.countryName,
    this.countryFlag,
    this.countryId,
    this.xpReward = 50,
    Key? key,
  }) : super(key: key);

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen>
    with TickerProviderStateMixin {
  late int _currentStepIndex;
  late AudioPlayer _audioPlayer;
  late CountriesService _countriesService;

  // Timer state
  int? _timerSeconds;
  Timer? _timer;
  bool _timerActive = false;
  bool _timerPaused = false;

  @override
  void initState() {
    super.initState();
    _currentStepIndex = 0;
    _audioPlayer = AudioPlayer();
    _countriesService = CountriesService(baseUrl: ApiService.baseUrl);
    print("USANDO COOKING MODE NUEVO");
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Delay disposal para que terminen sonidos
    Future.delayed(const Duration(milliseconds: 4000), () {
      _audioPlayer.dispose();
    });
    super.dispose();
  }

  void _startTimer() {
    final currentStep = widget.steps[_currentStepIndex];
    final timerDuration = currentStep['timerDurationSeconds'] as int?;

    if (timerDuration == null || timerDuration <= 0) return;
    if (_timerActive) return;

    setState(() {
      _timerSeconds = timerDuration;
      _timerActive = true;
      _timerPaused = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_timerPaused && _timerSeconds! > 0) {
        setState(() {
          _timerSeconds = _timerSeconds! - 1;
        });
      }

      if (_timerSeconds == 0 && !_timerPaused) {
        _timer?.cancel();
        _onTimerFinished();
      }
    });
  }

  void _pauseTimer() {
    if (_timerActive) {
      setState(() => _timerPaused = !_timerPaused);
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      _timerActive = false;
      _timerPaused = false;
      _timerSeconds = null;
    });
  }

  Future<void> _onTimerFinished() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alarma.mp3'));
    } catch (e) {
      debugPrint('Error playing alarm: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏰', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              Text(
                '¡Tiempo finalizado!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF27AE60),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continuar',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    setState(() {
      _timerActive = false;
      _timerPaused = false;
    });
  }

  void _goToNextStep() {
    if (_timerActive) return;

    widget.onStepComplete(_currentStepIndex);

    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() => _currentStepIndex++);
    } else {
      _showRecipeCompleted();
    }
  }

  void _goToPreviousStep() {
    if (_currentStepIndex > 0 && !_timerActive) {
      setState(() => _currentStepIndex--);
    }
  }

  void _showRecipeCompleted() {
    // First show planet animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                widget.countryName != null
                    ? '🌍 ¡Has desbloqueado ${widget.countryName}!'
                    : '🎉 ¡Receta completada!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF27AE60),
                ),
              ),
              const SizedBox(height: 24),

              // Planet animation
              SizedBox(
                height: 320,
                child: EarthPlanetWidget(
                  countryName: widget.countryName,
                  countryFlag: widget.countryFlag,
                  onComplete: () {
                    // After animation, close and show success
                    Navigator.of(dialogContext).pop();
                    _showRecipeSuccessDialog();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markCountryVisited() async {
    if (widget.countryId == null || widget.countryId!.isEmpty) return;

    try {
      final token = ApiService.getToken();
      if (token == null) return;

      await _countriesService.markCountryVisited(token, widget.countryId!);
      print('Country ${widget.countryName} marked as visited');
    } catch (e) {
      print('Error marking country visited: $e');
    }
  }

  void _showRecipeSuccessDialog() {
    // Mark country as visited in background
    _markCountryVisited();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 100)),
              const SizedBox(height: 16),
              Text(
                '¡Receta completada!',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF27AE60),
                ),
              ),
              if (widget.recipeName != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.recipeName!,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
              if (widget.countryName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.countryFlag != null &&
                          widget.countryFlag!.isNotEmpty)
                        Text(
                          widget.countryFlag!,
                          style: const TextStyle(fontSize: 24),
                        ),
                      if (widget.countryFlag != null &&
                          widget.countryFlag!.isNotEmpty)
                        const SizedBox(width: 8),
                      Text(
                        widget.countryName!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '+',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  Text(
                    '${widget.xpReward}',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'XP',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Volver',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'Sin pasos disponibles',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
        ),
      );
    }

    final step = widget.steps[_currentStepIndex];
    // Detectar si hay una card tipo timer
    final List<dynamic> cards = step['cards'] is List ? step['cards'] : [];
    final timerCard = cards.firstWhere(
      (c) => c is Map && c['type'] == 'timer',
      orElse: () => null,
    );
    final hasTimerCard =
        timerCard != null &&
        timerCard['content'] != null &&
        (timerCard['content']['duration'] ?? 0) > 0;
    final hasTimer =
        (step['timerDurationSeconds'] as int?) != null &&
        (step['timerDurationSeconds'] as int) > 0;

    return Scaffold(
      body: Container(
        color: const Color(0xFF0F172A),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (_currentStepIndex > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _goToPreviousStep,
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Paso ${_currentStepIndex + 1} de ${widget.steps.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_currentStepIndex + 1) / widget.steps.length,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF27AE60),
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  child: SingleChildScrollView(
                    key: ValueKey<int>(_currentStepIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Image
                          if (step['image'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                step['image'],
                                height: 280,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 280,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade700,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 32),

                          // Title
                          Text(
                            step['title'] ?? 'Paso ${_currentStepIndex + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            step['description'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Timer Card (Duolingo Style)
                          if (hasTimerCard) ...[
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.25),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.timer,
                                    size: 48,
                                    color: Colors.deepOrange,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Timer',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_timerActive)
                                    Text(
                                      _formatTime(_timerSeconds ?? 0),
                                      style: GoogleFonts.poppins(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.deepOrange,
                                      ),
                                    )
                                  else
                                    Text(
                                      '${timerCard['content']['duration']} seg',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.deepOrange.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  if (!_timerActive)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _timerSeconds =
                                              timerCard['content']['duration'];
                                          _timerActive = true;
                                          _timerPaused = false;
                                        });
                                        _timer = Timer.periodic(
                                          const Duration(seconds: 1),
                                          (timer) {
                                            if (!_timerPaused &&
                                                _timerSeconds! > 0) {
                                              setState(() {
                                                _timerSeconds =
                                                    _timerSeconds! - 1;
                                              });
                                            }
                                            if (_timerSeconds == 0 &&
                                                !_timerPaused) {
                                              _timer?.cancel();
                                              _onTimerFinished();
                                            }
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.timer),
                                      label: const Text('Iniciar cronómetro'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    )
                                  else
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: _pauseTimer,
                                          icon: Icon(
                                            _timerPaused
                                                ? Icons.play_arrow
                                                : Icons.pause,
                                          ),
                                          label: Text(
                                            _timerPaused
                                                ? 'Reanudar'
                                                : 'Pausar',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.deepOrange,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: _cancelTimer,
                                          icon: const Icon(Icons.close),
                                          label: const Text('Cancelar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ]
                          // Timer clásico (legacy)
                          else if (hasTimer) ...[
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  if (_timerActive)
                                    Text(
                                      _formatTime(_timerSeconds ?? 0),
                                      style: GoogleFonts.poppins(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFFF6B35),
                                      ),
                                    )
                                  else
                                    Text(
                                      '${step['timerDurationSeconds']} seg',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  if (!_timerActive)
                                    ElevatedButton.icon(
                                      onPressed: _startTimer,
                                      icon: const Icon(Icons.timer),
                                      label: const Text('Iniciar cronómetro'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFF6B35,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    )
                                  else
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: _pauseTimer,
                                          icon: Icon(
                                            _timerPaused
                                                ? Icons.play_arrow
                                                : Icons.pause,
                                          ),
                                          label: Text(
                                            _timerPaused
                                                ? 'Reanudar'
                                                : 'Pausar',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFFF6B35,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: _cancelTimer,
                                          icon: const Icon(Icons.close),
                                          label: const Text('Cancelar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _timerActive ? null : _goToNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      disabledBackgroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _currentStepIndex < widget.steps.length - 1
                          ? 'Siguiente'
                          : 'Listo',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _timerActive ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
