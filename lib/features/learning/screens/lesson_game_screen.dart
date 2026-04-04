import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/api_service.dart';
import '../../../core/audio_feedback_service.dart';
import '../../../core/image_optimize_service.dart';
import '../../../core/lives_service.dart';
import '../../../core/models/learning_node.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../widgets/cached_image.dart';
import '../../../widgets/interactive_animation_card.dart';
import '../../../widgets/step_timer_widget.dart';
import '../../../widgets/video_card_player.dart';
import '../../../theme/motion.dart';
import '../../cho/cho_assistant.dart';

/// Pantalla de leccion gamificada tipo Duolingo.
class LessonGameScreen extends StatefulWidget {
  final LearningNode node;
  final VoidCallback? onComplete;

  const LessonGameScreen({super.key, required this.node, this.onComplete});

  @override
  State<LessonGameScreen> createState() => _LessonGameScreenState();
}

class _LessonGameScreenState extends State<LessonGameScreen>
    with TickerProviderStateMixin {
  late int _currentStepIndex;
  int? _selectedAnswerIndex;
  bool? _isAnswerCorrect;
  final Set<int> _selectedChecklistQuizIndices = {};
  // match_categories: itemId -> categoryId colocado (null = en pool)
  final Map<String, String?> _matchPlacedItems = {};
  late AnimationController _shakeController;
  late final AudioPlayer _audioPlayer;
  late final LivesService _livesService;
  String _currentState = 'answering'; // answering, feedback, loading
  bool _isApplyingLifePenalty = false;
  int _currentLives = 3;
  bool _checklistAllChecked = false;
  bool _showChoGreeting = true;

  Widget _buildLivesIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_currentLives',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.favorite_rounded, color: Colors.red, size: 16),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentStepIndex = 0;
    _shakeController = AnimationController(
      duration: AppMotionDurations.emphasis,
      vsync: this,
    );
    _audioPlayer = AudioPlayer();
    _livesService = LivesService(baseUrl: ApiService.baseUrl);
    _loadLivesStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_precacheCriticalImages());
    });

    // Ocultar saludo de Cho después de 4 segundos
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showChoGreeting = false);
    });
  }

  Future<void> _precacheCriticalImages() async {
    if (!mounted || widget.node.steps.isEmpty) return;

    final urls = _collectLessonImageUrls();
    if (urls.isEmpty) return;

    final criticalUrls = urls.take(4).toList(growable: false);
    final deferredUrls = urls.skip(4).toList(growable: false);

    await Future.wait(criticalUrls.map(_precacheImageSafe));

    if (deferredUrls.isNotEmpty && mounted) {
      unawaited(_precacheDeferredImages(deferredUrls));
    }
  }

  List<String> _collectLessonImageUrls() {
    final urls = <String>[];
    final seen = <String>{};

    void addUrl(String? candidate) {
      final normalized = candidate?.trim();
      if (normalized == null ||
          normalized.isEmpty ||
          seen.contains(normalized)) {
        return;
      }
      seen.add(normalized);
      urls.add(normalized);
    }

    for (final step in widget.node.steps) {
      addUrl(step.image);

      if (step.cards == null) {
        continue;
      }
      for (final card in step.cards!) {
        final data = card['data'];
        if (data is! Map) {
          continue;
        }
        addUrl(data['imageUrl']?.toString());
      }
    }

    return urls;
  }

  Future<void> _precacheDeferredImages(List<String> deferredUrls) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    for (final url in deferredUrls) {
      if (!mounted) return;
      await _precacheImageSafe(url);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<void> _precacheImageSafe(String url) async {
    if (!mounted) return;
    try {
      final optimizedUrl = ImageOptimizeService.optimizeUrl(url);
      await precacheImage(CachedNetworkImageProvider(optimizedUrl), context);
    } catch (_) {}
  }

  @override
  void dispose() {
    _shakeController.dispose();
    // NO disponer el audio player inmediatamente para evitar cortar el sonido
    // Se dispondrá cuando se cierre completamente la pantalla
    Future.delayed(const Duration(milliseconds: 4000), () {
      _audioPlayer.dispose();
    });
    super.dispose();
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      // No esperar aquí - permitir que el sonido siga mientras se muestra el dialog
    } catch (e) {
      debugPrint('Error reproducing success sound: $e');
    }
  }

  Future<void> _loadLivesStatus() async {
    try {
      final token = ApiService.getToken();
      if (token == null || token.isEmpty) return;
      final status = await _livesService.getLivesStatus(token);
      if (!mounted) return;
      setState(() {
        _currentLives = (status['lives'] as num?)?.toInt() ?? _currentLives;
      });
    } catch (_) {}
  }

  Future<void> _applyLifePenaltyForMistake() async {
    if (_isApplyingLifePenalty) return;
    _isApplyingLifePenalty = true;
    try {
      final token = ApiService.getToken();
      if (token == null || token.isEmpty) return;

      final penalty = await _livesService.loseLive(token);
      final lives = (penalty['lives'] as num?)?.toInt() ?? _currentLives;
      final locked = penalty['lifesLocked'] == true || lives <= 0;

      if (!mounted) return;
      setState(() => _currentLives = lives);

      await _showLifeLostDialog(livesRemaining: lives, isLocked: locked);

      if (locked && mounted) {
        Navigator.of(context).pop(false);
      }
    } catch (_) {
      // Error handled silently - dialog already shown
    } finally {
      _isApplyingLifePenalty = false;
    }
  }

  Future<void> _showLifeLostDialog({
    required int livesRemaining,
    required bool isLocked,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_rounded, color: Colors.red, size: 34),
                const SizedBox(height: 8),
                Text(
                  isLocked ? 'Te quedaste sin vidas' : 'Perdiste 1 vida',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isLocked
                      ? 'No podés seguir esta lección por ahora. Volvé cuando recuperes vidas.'
                      : 'Cada error descuenta una vida. Te quedan $livesRemaining.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isLocked ? 'Entendido' : 'Continuar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleOptionSelected(int answerIndex) {
    if (_currentState != 'answering' || _selectedAnswerIndex != null) return;

    setState(() {
      _selectedAnswerIndex = answerIndex;
    });

    final step = widget.node.steps[_currentStepIndex];
    final options = _sanitizeOptions(step.options);
    if (answerIndex < 0 || answerIndex >= options.length) {
      return;
    }
    final selectedOption = options[answerIndex];
    final isCorrect = selectedOption == step.correctAnswer;

    if (!isCorrect) {
      AudioFeedbackService().playFail();
      if (_currentLives > 0) {
        setState(() {
          _currentLives -= 1;
        });
      }
      _shakeController.forward().then((_) => _shakeController.reset());
      unawaited(_applyLifePenaltyForMistake());
    }

    final feedbackDelay = isCorrect
        ? AppMotionDurations.feedbackSuccess
        : AppMotionDurations.feedbackError;

    Future.delayed(feedbackDelay, () {
      if (!mounted) return;
      setState(() {
        _isAnswerCorrect = isCorrect;
        _currentState = 'feedback';
      });
    });
  }

  void _handleContinue() async {
    final step = widget.node.steps[_currentStepIndex];
    final isQuizStep = _sanitizeOptions(step.options).length >= 2;
    final isChecklistQuizStep = _isQuizChecklistStep(step);

    if (isQuizStep && _isAnswerCorrect != true) {
      if (!mounted) return;
      setState(() {
        _selectedAnswerIndex = null;
        _isAnswerCorrect = null;
        _currentState = 'answering';
      });
      return;
    }

    if (isChecklistQuizStep && _isAnswerCorrect != true) {
      if (!mounted) return;
      setState(() {
        _selectedChecklistQuizIndices.clear();
        _isAnswerCorrect = null;
        _currentState = 'answering';
      });
      return;
    }

    final isMatchStep = _isMatchStep(step);
    if (isMatchStep && _isAnswerCorrect != true) {
      if (!mounted) return;
      setState(() {
        _matchPlacedItems.clear();
        _isAnswerCorrect = null;
        _currentState = 'answering';
      });
      return;
    }

    final isLastStep = _currentStepIndex == widget.node.steps.length - 1;

    if (isLastStep) {
      await _completeLessonNode();
    } else {
      setState(() {
        _currentStepIndex++;
        _selectedAnswerIndex = null;
        _isAnswerCorrect = null;
        _selectedChecklistQuizIndices.clear();
        _matchPlacedItems.clear();
        _currentState = 'answering';
        _checklistAllChecked = false;
      });
    }
  }

  Future<void> _completeLessonNode() async {
    setState(() => _currentState = 'loading');

    try {
      final result = await ApiService.completeNode(widget.node.id);
      if (!mounted) return;

      // Update user XP and level globally
      final totalXP = result['totalXP'] as int?;
      final level = result['level'] as int?;
      final progress = result['progress'] as Map<String, dynamic>?;
      final streak =
          (progress?['streak'] as num?)?.toInt() ??
          (result['streak'] as num?)?.toInt();
      if (totalXP != null && level != null) {
        context.read<AuthProvider>().updateXPAndLevel(
          totalXP,
          level,
          streak: streak,
        );
      }

      // Update progress in ProgressProvider
      context.read<ProgressProvider>().updateFromNodeCompletion(result);

      // Remove loading overlay
      setState(() => _currentState = 'answering');

      // Play success sound
      await _playSuccessSound();

      // Show celebration dialog and wait for user to press button
      await _showCelebration(result);
      if (!mounted) return;

      // Close lesson and return to path progression (node tree)
      Navigator.of(context).pop(true); // Only pop one route
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error completing lesson: $e');
      setState(() => _currentState = 'answering');
    }
  }

  Future<void> _showCelebration(Map<String, dynamic> result) async {
    final xpEarned = (result['xpEarned'] as num?)?.toInt() ?? 0;
    final totalXP = (result['totalXP'] as num?)?.toInt() ?? 0;
    final level = (result['level'] as num?)?.toInt() ?? 1;
    final isRepeat = result['isRepeat'] == true;
    final progress = result['progress'] as Map<String, dynamic>?;
    final streak =
        (progress?['streak'] as num?)?.toInt() ??
        (result['streak'] as num?)?.toInt() ??
        0;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: AppMotionDurations.celebrationEntrance,
      pageBuilder: (BuildContext dialogContext, _, __) {
        return _LessonCompletionCelebrationDialog(
          xpEarned: xpEarned,
          totalXP: totalXP,
          level: level,
          streak: streak,
          isRepeat: isRepeat,
          onContinue: () {
            // Opcional: sonido/haptic adicional al botón
            // await _audioPlayer.play(AssetSource('sounds/success.mp3'));
            Navigator.of(dialogContext).pop();
          },
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotionCurves.entrance,
        );
        final scale =
            Tween<double>(
              begin: AppMotionValues.dialogScaleStart,
              end: 1,
            ).animate(
              CurvedAnimation(parent: animation, curve: AppMotionCurves.bounce),
            );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  String _firstNonEmpty(List<String?> values, String fallback) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }

  List<String> _sanitizeOptions(List<String>? options) {
    return (options ?? const [])
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList();
  }

  /// Extrae el mensaje de feedback personalizado de las cards de quiz
  String? _getQuizFeedbackMessage(NodeStep step, {required bool isCorrect}) {
    if (step.cards == null || step.cards!.isEmpty) {
      return null;
    }

    for (final card in step.cards!) {
      final cardType = card['type']?.toString();
      if (cardType == 'quiz') {
        final content =
            (card['data'] as Map?) ?? (card['content'] as Map?) ?? {};
        // El admin guarda el feedback correcto en 'explanation'
        if (isCorrect) {
          final explanation = content['explanation']?.toString().trim();
          if (explanation != null && explanation.isNotEmpty) {
            return explanation;
          }
        }
        // Feedback incorrecto (si se implementa en el futuro)
        else {
          final incorrectFeedback = content['incorrectFeedback']
              ?.toString()
              .trim();
          if (incorrectFeedback != null && incorrectFeedback.isNotEmpty) {
            return incorrectFeedback;
          }
        }
      }
    }
    return null;
  }

  /// Extrae optionItems completos (con imágenes) de las cards de quiz
  List<Map<String, dynamic>>? _getQuizOptionItems(NodeStep step) {
    if (step.cards == null || step.cards!.isEmpty) return null;

    for (final card in step.cards!) {
      final cardType = card['type']?.toString();
      if (cardType == 'quiz') {
        final content =
            (card['data'] as Map?) ?? (card['content'] as Map?) ?? {};
        final optionItems = content['optionItems'];
        if (optionItems is List && optionItems.isNotEmpty) {
          final result = optionItems
              .map(
                (item) => item is Map
                    ? Map<String, dynamic>.from(item)
                    : {'text': item?.toString() ?? ''},
              )
              .toList();
          return result;
        }
      }
    }
    return null;
  }

  /// Detecta si el step tiene una card de tipo quiz_checklist
  bool _isQuizChecklistStep(NodeStep step) {
    if (step.cards == null || step.cards!.isEmpty) return false;
    return step.cards!.any((c) => c['type']?.toString() == 'quiz_checklist');
  }

  /// Extrae los datos del card quiz_checklist
  Map<String, dynamic>? _getQuizChecklistData(NodeStep step) {
    if (step.cards == null) return null;
    for (final card in step.cards!) {
      if (card['type']?.toString() == 'quiz_checklist') {
        return Map<String, dynamic>.from(
          (card['data'] as Map?) ?? (card['content'] as Map?) ?? {},
        );
      }
    }
    return null;
  }

  /// Extrae las opciones del quiz_checklist (lista de textos)
  List<String> _getChecklistQuizOptions(NodeStep step) {
    final data = _getQuizChecklistData(step);
    if (data == null) return [];
    final optionItems = data['optionItems'];
    if (optionItems is List && optionItems.isNotEmpty) {
      return optionItems
          .map((item) =>
              item is Map ? (item['text']?.toString() ?? '') : item.toString())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    final options = data['options'];
    if (options is List) {
      return options.map((o) => o.toString()).where((t) => t.isNotEmpty).toList();
    }
    return [];
  }

  /// Extrae optionItems completos (con imágenes) del quiz_checklist
  List<Map<String, dynamic>>? _getChecklistQuizOptionItems(NodeStep step) {
    final data = _getQuizChecklistData(step);
    if (data == null) return null;
    final optionItems = data['optionItems'];
    if (optionItems is List && optionItems.isNotEmpty) {
      return optionItems
          .map((item) => item is Map
              ? Map<String, dynamic>.from(item)
              : {'text': item?.toString() ?? ''})
          .toList();
    }
    return null;
  }

  /// Extrae los índices correctos del quiz_checklist
  List<int> _getChecklistQuizCorrectIndices(NodeStep step) {
    return step.correctIndices ?? [];
  }

  /// Toggle de selección en el quiz_checklist (answering state)
  void _handleChecklistQuizToggle(int index) {
    if (_currentState != 'answering') return;
    setState(() {
      if (_selectedChecklistQuizIndices.contains(index)) {
        _selectedChecklistQuizIndices.remove(index);
      } else {
        _selectedChecklistQuizIndices.add(index);
      }
    });
  }

  /// Verificar respuestas del quiz_checklist
  void _handleChecklistQuizSubmit(NodeStep step) {
    if (_currentState != 'answering') return;
    if (_selectedChecklistQuizIndices.isEmpty) return;

    final correct = _getChecklistQuizCorrectIndices(step);
    final selectedSorted = _selectedChecklistQuizIndices.toList()..sort();
    final correctSorted = List<int>.from(correct)..sort();
    final isCorrect =
        selectedSorted.length == correctSorted.length &&
        selectedSorted.every((i) => correctSorted.contains(i));

    if (!isCorrect) {
      AudioFeedbackService().playFail();
      if (_currentLives > 0) {
        setState(() => _currentLives -= 1);
      }
      _shakeController.forward().then((_) => _shakeController.reset());
      unawaited(_applyLifePenaltyForMistake());
    }

    final feedbackDelay = isCorrect
        ? AppMotionDurations.feedbackSuccess
        : AppMotionDurations.feedbackError;

    Future.delayed(feedbackDelay, () {
      if (!mounted) return;
      setState(() {
        _isAnswerCorrect = isCorrect;
        _currentState = 'feedback';
      });
    });
  }

  // ── match_categories helpers ────────────────────────────────────────────────

  bool _isMatchStep(NodeStep step) {
    if (step.cards == null || step.cards!.isEmpty) return false;
    return step.cards!.any((c) => c['type']?.toString() == 'match_categories');
  }

  Map<String, dynamic>? _getMatchData(NodeStep step) {
    if (step.cards == null) return null;
    for (final card in step.cards!) {
      if (card['type']?.toString() == 'match_categories') {
        return Map<String, dynamic>.from(
          (card['data'] as Map?) ?? (card['content'] as Map?) ?? {},
        );
      }
    }
    return null;
  }

  void _handleMatchDrop(String itemId, String? categoryId) {
    if (_currentState != 'answering') return;
    setState(() => _matchPlacedItems[itemId] = categoryId);
  }

  void _handleMatchSubmit(NodeStep step) {
    if (_currentState != 'answering') return;
    final data = _getMatchData(step);
    if (data == null) return;
    final items = data['items'] as List? ?? [];
    // Todos los ítems con categoryId != null deben estar en su categoría.
    // Todos los ítems con categoryId == null deben estar en el pool (null).
    bool isCorrect = true;
    for (final item in items) {
      final itemMap = item as Map?;
      final id = itemMap?['id']?.toString() ?? '';
      final expected = itemMap?['categoryId']?.toString();
      final placed = _matchPlacedItems[id];
      if (expected != placed) {
        isCorrect = false;
        break;
      }
    }

    if (!isCorrect) {
      AudioFeedbackService().playFail();
      if (_currentLives > 0) setState(() => _currentLives -= 1);
      _shakeController.forward().then((_) => _shakeController.reset());
      unawaited(_applyLifePenaltyForMistake());
    }

    final feedbackDelay = isCorrect
        ? AppMotionDurations.feedbackSuccess
        : AppMotionDurations.feedbackError;

    Future.delayed(feedbackDelay, () {
      if (!mounted) return;
      setState(() {
        _isAnswerCorrect = isCorrect;
        _currentState = 'feedback';
      });
    });
  }

  String _normalizeContentText(String? value) {
    if (value == null) {
      return '';
    }
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  Map<String, dynamic> _normalizeImageDisplay(dynamic raw) {
    if (raw is! Map) {
      return {'fit': 'cover', 'zoom': 1.0, 'offsetX': 0.0, 'offsetY': 0.0};
    }

    final fit = raw['fit']?.toString() ?? 'cover';
    final zoom = raw['zoom'] is num
        ? (raw['zoom'] as num).toDouble().clamp(1.0, 2.5)
        : double.tryParse('${raw['zoom']}')?.clamp(1.0, 2.5) ?? 1.0;
    final offsetX = raw['offsetX'] is num
        ? (raw['offsetX'] as num).toDouble().clamp(-1.0, 1.0)
        : double.tryParse('${raw['offsetX']}')?.clamp(-1.0, 1.0) ?? 0.0;
    final offsetY = raw['offsetY'] is num
        ? (raw['offsetY'] as num).toDouble().clamp(-1.0, 1.0)
        : double.tryParse('${raw['offsetY']}')?.clamp(-1.0, 1.0) ?? 0.0;

    return {
      'fit':
          const [
            'cover',
            'contain',
            'fill',
            'fitWidth',
            'fitHeight',
          ].contains(fit)
          ? fit
          : 'cover',
      'zoom': zoom,
      'offsetX': offsetX,
      'offsetY': offsetY,
    };
  }

  BoxFit _boxFitFromDisplay(String fit) {
    switch (fit) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'cover':
      default:
        return BoxFit.cover;
    }
  }

  bool _parseBoolLike(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }

    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }

    return fallback;
  }

  bool _looksLikeVideoUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return false;
    }

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('data:video/')) {
      return true;
    }

    final parsed = Uri.tryParse(trimmed);
    final path = (parsed?.path ?? lower).toLowerCase();
    const videoExtensions = [
      '.mp4',
      '.webm',
      '.mov',
      '.m4v',
      '.m3u8',
      '.avi',
      '.mkv',
    ];

    if (videoExtensions.any(path.endsWith) ||
        path.contains('/videos/') ||
        path.contains('/video/')) {
      return true;
    }

    final query = parsed?.query.toLowerCase() ?? '';
    return query.contains('resource_type=video') ||
        query.contains('format=mp4');
  }

  Widget _buildDisplayAwareCachedImage({
    required String imageUrl,
    required double height,
    required Map<String, dynamic> display,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
  }) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFFF3F4F6),
        child: Transform.scale(
          scale: display['zoom'] as double,
          child: CachedImage(
            imageUrl: imageUrl,
            fit: _boxFitFromDisplay(display['fit'] as String),
            alignment: Alignment(
              display['offsetX'] as double,
              display['offsetY'] as double,
            ),
            errorFallback: SizedBox(
              height: height,
              child: const Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
        ),
      ),
    );
  }

  bool _stepInstructionIsDuplicatedByCards(NodeStep step) {
    final instructionNorm = _normalizeContentText(step.instruction);
    if (instructionNorm.isEmpty || step.cards == null || step.cards!.isEmpty) {
      return false;
    }

    for (final card in step.cards!) {
      final content = (card['data'] as Map?) ?? (card['content'] as Map?) ?? {};
      final candidates = [
        content['text']?.toString(),
        content['description']?.toString(),
        content['instruction']?.toString(),
        card['text']?.toString(),
        card['description']?.toString(),
        card['instruction']?.toString(),
      ];

      for (final candidate in candidates) {
        if (_normalizeContentText(candidate) == instructionNorm) {
          return true;
        }
      }
    }

    return false;
  }

  Widget _buildTextCard({
    required String text,
    IconData icon = Icons.menu_book_rounded,
    Color iconColor = const Color(0xFF27AE60),
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _stepHasChecklist(NodeStep step) =>
      step.cards?.any((c) =>
          c['type'] == 'checklist' ||
          c['type'] == 'recipe_builder' ||
          c['type'] == 'cutting_board') ??
      false;

  Widget _buildQuizChecklistWidget(NodeStep step) {
    final optionItemsFull = _getChecklistQuizOptionItems(step);
    final options = _getChecklistQuizOptions(step);
    final correctIndices = _getChecklistQuizCorrectIndices(step);
    final inFeedback = _currentState == 'feedback';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instrucción: cuántas respuestas correctas hay
        if (!inFeedback)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Selecciona ${correctIndices.length} respuesta${correctIndices.length > 1 ? 's' : ''} correcta${correctIndices.length > 1 ? 's' : ''}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        // Lista de opciones
        ...List.generate(options.length, (index) {
          final optionText = options[index];
          final optionItem = optionItemsFull != null && index < optionItemsFull.length
              ? optionItemsFull[index]
              : null;
          final imageUrl = optionItem?['imageUrl']?.toString();
          final isSelected = _selectedChecklistQuizIndices.contains(index);
          final isCorrect = correctIndices.contains(index);

          Color cardColor = Colors.white;
          Color borderColor = const Color(0xFFE5E7EB);
          double borderWidth = 2;
          Widget? trailingIcon;

          if (inFeedback) {
            if (isCorrect && isSelected) {
              // Correcto y seleccionado: verde
              cardColor = const Color(0xFFD1FAE5);
              borderColor = const Color(0xFF10B981);
              borderWidth = 3;
              trailingIcon = const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF059669));
            } else if (isCorrect && !isSelected) {
              // Correcto pero no seleccionado: amarillo (faltó marcar)
              cardColor = const Color(0xFFFEF3C7);
              borderColor = const Color(0xFFF59E0B);
              borderWidth = 3;
              trailingIcon = const Icon(Icons.radio_button_unchecked_rounded,
                  color: Color(0xFFF59E0B));
            } else if (!isCorrect && isSelected) {
              // Incorrecto y seleccionado: rojo
              cardColor = const Color(0xFFFEE2E2);
              borderColor = const Color(0xFFEF4444);
              borderWidth = 3;
              trailingIcon =
                  const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626));
            } else {
              // No correcto y no seleccionado: gris
              cardColor = const Color(0xFFF9FAFB);
              borderColor = const Color(0xFFF3F4F6);
            }
          } else if (isSelected) {
            cardColor = const Color(0xFFD4EDDA);
            borderColor = const Color(0xFF27AE60);
            borderWidth = 3;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedContainer(
              duration: AppMotionDurations.medium,
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(color: borderColor, width: borderWidth),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  if (isSelected && !inFeedback)
                    BoxShadow(
                      color:
                          const Color(0xFF27AE60).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: inFeedback
                    ? null
                    : () => _handleChecklistQuizToggle(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Checkbox visual
                      AnimatedContainer(
                        duration: AppMotionDurations.quick,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected && !inFeedback
                              ? const Color(0xFF27AE60)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected && !inFeedback
                                ? const Color(0xFF27AE60)
                                : const Color(0xFF9CA3AF),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: isSelected && !inFeedback
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      // Imagen opcional
                      if (imageUrl != null && imageUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedImage(
                            imageUrl: imageUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorFallback: const Icon(
                                Icons.broken_image_outlined,
                                size: 28,
                                color: Color(0xFF9CA3AF)),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Texto de la opción
                      Expanded(
                        child: Text(
                          optionText,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: inFeedback && !isCorrect && !isSelected
                                ? const Color(0xFFD1D5DB)
                                : const Color(0xFF1F2937),
                            height: 1.3,
                          ),
                        ),
                      ),
                      // Ícono de feedback
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        trailingIcon,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Widget de unir conceptos (drag & drop categorías) ──────────────────────

  Widget _buildMatchCategoriesWidget(NodeStep step) {
    final data = _getMatchData(step);
    if (data == null) return const SizedBox.shrink();

    final categories = (data['categories'] as List? ?? [])
        .map((c) => Map<String, dynamic>.from(c as Map))
        .toList();
    final allItems = (data['items'] as List? ?? [])
        .map((it) => Map<String, dynamic>.from(it as Map))
        .toList();

    final inFeedback = _currentState == 'feedback';

    // Ítems en el pool: los que no han sido colocados en ninguna categoría
    final poolItems = allItems
        .where((it) => _matchPlacedItems[it['id']?.toString()] == null)
        .toList();

    Color itemColor(Map<String, dynamic> item, {required bool inCategory}) {
      if (!inFeedback) {
        return inCategory ? const Color(0xFFD4EDDA) : Colors.white;
      }
      // Feedback: correcto = verde, incorrecto = rojo
      final placed = _matchPlacedItems[item['id']?.toString()];
      final expected = item['categoryId']?.toString();
      if (placed == expected) return const Color(0xFFD1FAE5);
      return const Color(0xFFFEE2E2);
    }

    Color itemBorder(Map<String, dynamic> item, {required bool inCategory}) {
      if (!inFeedback) {
        return inCategory
            ? const Color(0xFF27AE60)
            : const Color(0xFFE5E7EB);
      }
      final placed = _matchPlacedItems[item['id']?.toString()];
      final expected = item['categoryId']?.toString();
      if (placed == expected) return const Color(0xFF10B981);
      return const Color(0xFFEF4444);
    }

    Widget buildItemChip(Map<String, dynamic> item,
        {required bool inCategory}) {
      final text = item['text']?.toString() ?? '';
      final itemId = item['id']?.toString() ?? '';
      final chip = AnimatedContainer(
        duration: AppMotionDurations.quick,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: itemColor(item, inCategory: inCategory),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: itemBorder(item, inCategory: inCategory),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inFeedback) ...[
              Icon(
                _matchPlacedItems[itemId] == item['categoryId']?.toString()
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_outlined,
                size: 14,
                color:
                    _matchPlacedItems[itemId] == item['categoryId']?.toString()
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      );
      if (inFeedback) return chip;
      return LongPressDraggable<String>(
        data: itemId,
        delay: const Duration(milliseconds: 120),
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.85,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: chip),
        child: chip,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Instrucción ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Arrastra cada elemento a su categoría',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        // ── Categorías con drop targets ───────────────────────────────
        ...categories.map((cat) {
          final catId = cat['id']?.toString() ?? '';
          final catName = cat['name']?.toString() ?? '';
          final placedHere = allItems
              .where((it) =>
                  _matchPlacedItems[it['id']?.toString()] == catId)
              .toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DragTarget<String>(
              onWillAcceptWithDetails: (details) =>
                  !inFeedback && details.data.isNotEmpty,
              onAcceptWithDetails: (details) =>
                  _handleMatchDrop(details.data, catId),
              builder: (context, candidateData, rejectedData) {
                final isHovered = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: AppMotionDurations.quick,
                  constraints: const BoxConstraints(minHeight: 72),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isHovered
                          ? const Color(0xFF10B981)
                          : const Color(0xFFD1D5DB),
                      width: isHovered ? 2.5 : 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      if (placedHere.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: placedHere
                              .map((it) => GestureDetector(
                                    onTap: inFeedback
                                        ? null
                                        : () => _handleMatchDrop(
                                            it['id']?.toString() ?? '',
                                            null),
                                    child: buildItemChip(it,
                                        inCategory: true),
                                  ))
                              .toList(),
                        ),
                      ] else if (!isHovered)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Suelta aquí',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
        // ── Pool de ítems ─────────────────────────────────────────────
        DragTarget<String>(
          onWillAcceptWithDetails: (details) =>
              !inFeedback && details.data.isNotEmpty,
          onAcceptWithDetails: (details) =>
              _handleMatchDrop(details.data, null),
          builder: (context, candidateData, rejectedData) {
            final isHovered = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: AppMotionDurations.quick,
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHovered
                    ? const Color(0xFFF0F9FF)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isHovered
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFFD1D5DB),
                  width: isHovered ? 2.5 : 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elementos disponibles',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (poolItems.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: poolItems
                          .map((it) =>
                              buildItemChip(it, inCategory: false))
                          .toList(),
                    )
                  else
                    Text(
                      inFeedback
                          ? 'Todos los elementos fueron colocados'
                          : 'Todos asignados',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        // ── Botón Verificar (solo en answering) ───────────────────────
        if (!inFeedback)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton.icon(
              onPressed: _matchPlacedItems.isNotEmpty
                  ? () => _handleMatchSubmit(step)
                  : null,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                'Verificar',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _matchPlacedItems.isNotEmpty
                    ? const Color(0xFF27AE60)
                    : const Color(0xFFD1D5DB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: _matchPlacedItems.isNotEmpty ? 6 : 0,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildContentCards(NodeStep step, {bool excludeQuiz = false}) {
    final cards = <Widget>[];
    final hasCards = step.cards != null && step.cards!.isNotEmpty;

    // Auto-timer desde el campo duration del paso (si no hay card timer explícita)
    final hasTimerCard = hasCards &&
        step.cards!.any((c) => c['type']?.toString() == 'timer');
    if (step.duration > 0 && !hasTimerCard) {
      cards.add(
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1F2937)),
          ),
          child: Column(
            children: [
              const Icon(Icons.timer, color: Color(0xFF22C55E), size: 36),
              const SizedBox(height: 8),
              Text(
                'Tiempo estimado: ${step.duration >= 60 ? '${step.duration ~/ 60} min' : '${step.duration} seg'}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF22C55E),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              StepTimerWidget(
                durationSeconds: step.duration,
                onTimerEnd: () {},
              ),
            ],
          ),
        ),
      );
    }

    if (hasCards) {
      for (final card in step.cards!) {
        final cardType = card['type']?.toString();
        if (excludeQuiz && (cardType == 'quiz' || cardType == 'quiz_checklist' || cardType == 'match_categories')) {
          continue;
        }
        final content =
            (card['data'] as Map?) ?? (card['content'] as Map?) ?? {};
        if (cardType == 'timer') {
          final duration =
              int.tryParse(
                content['duration']?.toString() ??
                    content['seconds']?.toString() ??
                    content['time']?.toString() ??
                    '',
              ) ??
              0;

          cards.add(
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer, color: Color(0xFF22C55E), size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    'Timer',
                    style: TextStyle(
                      color: Color(0xFF22C55E),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StepTimerWidget(durationSeconds: duration, onTimerEnd: () {}),
                ],
              ),
            ),
          );
          continue;
        }

        // Animation card: Interactive animations
        if (cardType == 'animation') {
          cards.add(
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: InteractiveAnimationCard(
                data: Map<String, dynamic>.from(content),
              ),
            ),
          );
          continue;
        }

        final listItems = content['items'] is List
            ? List<dynamic>.from(content['items'])
            : (card['items'] is List ? List<dynamic>.from(card['items']) : []);

        final cardTitle = _firstNonEmpty([
          content['title']?.toString(),
          card['title']?.toString(),
          card['name']?.toString(),
          card['label']?.toString(),
        ], '');
        final cardBody = _firstNonEmpty([
          content['text']?.toString(),
          content['description']?.toString(),
          content['instruction']?.toString(),
          card['text']?.toString(),
          card['description']?.toString(),
          card['instruction']?.toString(),
        ], '');
        final cardImage =
            content['url']?.toString() ??
            content['imageUrl']?.toString() ??
            content['media']?.toString() ??
            card['image']?.toString() ??
            card['media']?.toString();
        final cardVideo = _firstNonEmpty([
          content['videoUrl']?.toString(),
          content['video']?.toString(),
          card['videoUrl']?.toString(),
          card['video']?.toString(),
          if (cardType == 'video') content['url']?.toString(),
          if (cardType == 'video') content['media']?.toString(),
          if (cardType == 'video') card['media']?.toString(),
          if (_looksLikeVideoUrl(content['url']?.toString()))
            content['url']?.toString(),
          if (_looksLikeVideoUrl(content['media']?.toString()))
            content['media']?.toString(),
          if (_looksLikeVideoUrl(card['media']?.toString()))
            card['media']?.toString(),
          if (_looksLikeVideoUrl(card['image']?.toString()))
            card['image']?.toString(),
        ], '');
        final cardImageDisplay = _normalizeImageDisplay(
          content['display'] ?? content['imageDisplay'],
        );

        final isBold = content['isBold'] ?? card['isBold'] ?? false;
        final isItalic = content['isItalic'] ?? card['isItalic'] ?? false;

        if (cardType == 'list' && listItems.isNotEmpty) {
          final listStyle =
              content['listStyle']?.toString() ??
              card['listStyle']?.toString() ??
              'checks';
          final filteredItems = listItems
              .map((e) => e?.toString() ?? '')
              .where((e) => e.trim().isNotEmpty)
              .toList();
          cards.add(
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cardTitle.isNotEmpty)
                    Text(
                      cardTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  if (cardTitle.isNotEmpty) const SizedBox(height: 8),
                  ...List.generate(filteredItems.length, (i) {
                    final item = filteredItems[i];
                    Widget leading;
                    if (listStyle == 'crosses') {
                      leading = const Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color: Color(0xFFDC2626),
                      );
                    } else if (listStyle == 'numbered') {
                      leading = Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      );
                    } else {
                      leading = const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Color(0xFF27AE60),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          leading,
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF1F2937),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
          continue;
        }

        if (cardType == 'checklist' && listItems.isNotEmpty) {
          final filteredChecklist = listItems
              .map((e) => e?.toString() ?? '')
              .where((e) => e.trim().isNotEmpty)
              .toList();
          cards.add(
            _ChecklistCardWidget(
              title: cardTitle,
              items: filteredChecklist,
              onAllChecked: () => setState(() => _checklistAllChecked = true),
            ),
          );
          continue;
        }

        if (cardType == 'recipe_builder') {
          final ingRaw = content['ingredients'] as List?;
          final ingredients = ingRaw
                  ?.map((e) =>
                      Map<String, dynamic>.from(e as Map? ?? {}))
                  .toList() ??
              [];
          if (ingredients.isNotEmpty) {
            cards.add(
              _RecipeBuilderCardWidget(
                title: cardTitle,
                instruction:
                    content['instruction']?.toString() ?? '',
                baseImage: content['baseImage']?.toString() ?? '',
                finalImage: content['finalImage']?.toString() ?? '',
                finishLabel:
                    content['finishLabel']?.toString() ?? '¡Listo!',
                ingredients: ingredients,
                onCompleted: () =>
                    setState(() => _checklistAllChecked = true),
              ),
            );
            continue;
          }
        }

        if (cardType == 'cutting_board') {
          final framesRaw = content['frames'] as List?;
          final frames = framesRaw
                  ?.map((e) =>
                      Map<String, dynamic>.from(e as Map? ?? {}))
                  .toList() ??
              [];
          if (frames.isNotEmpty) {
            cards.add(
              _CuttingBoardCardWidget(
                instruction: content['instruction']?.toString() ?? '',
                baseImage: content['baseImage']?.toString() ?? '',
                frames: frames,
                onCompleted: () =>
                    setState(() => _checklistAllChecked = true),
              ),
            );
            continue;
          }
        }

        final hasVideo = cardVideo.isNotEmpty;
        final hasImage = !hasVideo && cardImage != null && cardImage.isNotEmpty;
        if (cardTitle.isEmpty && cardBody.isEmpty && !hasImage && !hasVideo) {
          continue;
        }

        final showCardBody =
            cardBody.isNotEmpty &&
            _normalizeContentText(cardBody) != _normalizeContentText(cardTitle);

        cards.add(
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cardTitle.isNotEmpty) ...[
                  Text(
                    cardTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
                if (showCardBody) ...[
                  if (cardTitle.isNotEmpty) const SizedBox(height: 8),
                  Text(
                    cardBody,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF4B5563),
                      height: 1.4,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
                if (hasVideo) ...[
                  if (cardTitle.isNotEmpty || showCardBody)
                    const SizedBox(height: 12),
                  VideoCardPlayer(
                    videoUrl: cardVideo,
                    autoPlay: true,
                    showControls: false,
                    initialLooping: _parseBoolLike(
                      content['videoLoop'] ??
                          content['loop'] ??
                          card['videoLoop'] ??
                          card['loop'],
                    ),
                    initialMuted: _parseBoolLike(
                      content['videoMuted'] ??
                          content['muted'] ??
                          card['videoMuted'] ??
                          card['muted'],
                    ),
                    completionText: _firstNonEmpty([
                      content['videoEndText']?.toString(),
                      content['completionText']?.toString(),
                      card['videoEndText']?.toString(),
                      card['completionText']?.toString(),
                    ], ''),
                  ),
                ],
                if (hasImage) ...[
                  if (cardTitle.isNotEmpty || showCardBody)
                    const SizedBox(height: 12),
                  _buildDisplayAwareCachedImage(
                    imageUrl: cardImage,
                    height: 160,
                    display: cardImageDisplay,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ],
            ),
          ),
        );
      }
    }

    if (!hasCards && step.instruction.isNotEmpty) {
      cards.add(_buildTextCard(text: step.instruction));
    }

    if (step.feedback != null && step.feedback!.isNotEmpty) {
      cards.add(
        _buildTextCard(
          text: step.feedback!,
          icon: Icons.emoji_events_rounded,
          iconColor: const Color(0xFF22C55E),
        ),
      );
    }

    if (step.checklist != null && step.checklist!.isNotEmpty) {
      cards.add(
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Checklist',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              ...step.checklist!.map((item) {
                final label =
                    item['item']?.toString() ??
                    item['label']?.toString() ??
                    item['text']?.toString() ??
                    'Paso';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Color(0xFF27AE60),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF1F2937),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    if (step.tips != null && step.tips!.isNotEmpty) {
      cards.add(
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              ...step.tips!.map((tip) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                      Expanded(
                        child: Text(
                          tip,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF1F2937),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    if (cards.isEmpty) {
      final bodyText = _firstNonEmpty([
        step.instruction,
        step.description,
        step.feedback,
        step.question,
      ], 'Este paso no tiene contenido adicional.');
      cards.add(_buildTextCard(text: bodyText));
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.node.steps.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F7F4),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Color(0xFF1F2937),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Leccion',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: _buildLivesIndicator()),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🍳', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'Esta leccion no tiene pasos aun.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Vuelve mas tarde o elige otra leccion.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final step = widget.node.steps[_currentStepIndex];
    final options = _sanitizeOptions(step.options);
    final optionItems = _getQuizOptionItems(step);
    final isQuizStep = options.length >= 2;
    final isChecklistQuizStep = _isQuizChecklistStep(step);
    final isMatchStep = _isMatchStep(step);
    final contentCards = _buildContentCards(
      step,
      excludeQuiz: isQuizStep || isChecklistQuizStep || isMatchStep,
    );
    final showStepInstruction =
        step.instruction.isNotEmpty &&
        !_stepInstructionIsDuplicatedByCards(step);

    final currentStepDesc = (widget.node.steps.isNotEmpty &&
            _currentStepIndex < widget.node.steps.length)
        ? widget.node.steps[_currentStepIndex].title
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pregunta ${_currentStepIndex + 1}/${widget.node.steps.length}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _buildLivesIndicator()),
          ),
        ],
        centerTitle: false,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 60,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value:
                            (_currentStepIndex + 1) / widget.node.steps.length,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF27AE60),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 200),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    if (step.image != null && step.image!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 30),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedImage(
                            imageUrl: step.image!,
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorFallback: const SizedBox(
                              height: 240,
                              child: Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (showStepInstruction)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          step.instruction,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (isQuizStep) const SizedBox(height: 16),
                    if (contentCards.isNotEmpty) ...contentCards,
                    if (contentCards.isNotEmpty) const SizedBox(height: 24),
                    if (isQuizStep) const SizedBox(height: 16),
                    if (isQuizStep)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.7,
                          children: List.generate(options.length, (index) {
                            final option = options[index];
                            final optionItem =
                                optionItems != null &&
                                    index < optionItems.length
                                ? optionItems[index]
                                : null;
                            final optionImageUrl = optionItem?['imageUrl']
                                ?.toString();
                            final isSelected = _selectedAnswerIndex == index;
                            final isCorrectAnswer =
                                option == step.correctAnswer;

                            Color cardColor = const Color(0xFFFFFFFF);
                            Color borderColor = const Color(0xFFE5E7EB);
                            double borderWidth = 2;
                            Color textColor = const Color(0xFF1F2937);
                            Color iconColor = Colors.transparent;
                            IconData? iconData;
                            double scale = 1.0;

                            if (_currentState == 'answering') {
                              if (isSelected) {
                                cardColor = const Color(0xFFD4EDDA);
                                borderColor = const Color(0xFF27AE60);
                                borderWidth = 3;
                                scale = 0.95;
                              }
                            } else if (_currentState == 'feedback') {
                              if (isCorrectAnswer) {
                                cardColor = const Color(0xFFD4EDDA);
                                borderColor = const Color(0xFF27AE60);
                                borderWidth = 3;
                                iconData = Icons.check_circle_rounded;
                                iconColor = const Color(0xFF27AE60);
                              } else if (isSelected &&
                                  _isAnswerCorrect == false) {
                                cardColor = const Color(0xFFF8D7DA);
                                borderColor = const Color(0xFFDC3545);
                                borderWidth = 3;
                                iconData = Icons.cancel_rounded;
                                iconColor = const Color(0xFFDC3545);
                              } else {
                                textColor = const Color(0xFFD1D5DB);
                                borderColor = const Color(0xFFF3F4F6);
                                cardColor = const Color(0xFFF9FAFB);
                              }
                            }

                            Widget card = AnimatedScale(
                              scale: scale,
                              duration: AppMotionDurations.quick,
                              child: GestureDetector(
                                onTap:
                                    _currentState == 'answering' &&
                                        _selectedAnswerIndex == null
                                    ? () => _handleOptionSelected(index)
                                    : null,
                                child: AnimatedContainer(
                                  duration: AppMotionDurations.medium,
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    border: Border.all(
                                      color: borderColor,
                                      width: borderWidth,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      if (isSelected &&
                                          _currentState == 'answering')
                                        BoxShadow(
                                          color: const Color(
                                            0xFF27AE60,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 8,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (iconData != null)
                                          Icon(
                                            iconData,
                                            size: 40,
                                            color: iconColor,
                                          )
                                        else if (optionImageUrl != null &&
                                            optionImageUrl.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: CachedImage(
                                              imageUrl: optionImageUrl,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorFallback: const Icon(
                                                Icons.broken_image_outlined,
                                                size: 40,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ),
                                        if (iconData != null ||
                                            (optionImageUrl != null &&
                                                optionImageUrl.isNotEmpty))
                                          const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            option,
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );

                            if (isSelected &&
                                _isAnswerCorrect == false &&
                                _currentState == 'feedback') {
                              card = AnimatedBuilder(
                                animation: _shakeController,
                                builder: (context, child) {
                                  final shake =
                                      math.sin(
                                        _shakeController.value * 4 * 3.14159,
                                      ) *
                                      AppMotionValues.shakeDistance;
                                  return Transform.translate(
                                    offset: Offset(shake, 0),
                                    child: child,
                                  );
                                },
                                child: card,
                              );
                            }

                            return card;
                          }),
                        ),
                      ),
                    // Quiz checklist: lista vertical con checkboxes
                    if (isChecklistQuizStep)
                      _buildQuizChecklistWidget(step),
                    if (isMatchStep)
                      _buildMatchCategoriesWidget(step),
                    if (!isQuizStep && !isChecklistQuizStep && !isMatchStep && contentCards.isEmpty)
                      ..._buildContentCards(step),
                  ]),
                ),
              ),
            ],
          ),
          if (_currentState == 'feedback' && (isQuizStep || isChecklistQuizStep || isMatchStep))
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: Builder(
                builder: (context) {
                  final feedbackMessage = _getQuizFeedbackMessage(
                    step,
                    isCorrect: _isAnswerCorrect == true,
                  );

                  // Siempre mostrar feedback, con mensaje por defecto si no hay personalizado
                  final displayMessage =
                      feedbackMessage ??
                      (_isAnswerCorrect == true
                          ? '¡Correcto! ✓'
                          : 'Intenta de nuevo');

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isAnswerCorrect == true
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isAnswerCorrect == true
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isAnswerCorrect == true
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: _isAnswerCorrect == true
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            displayMessage,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _isAnswerCorrect == true
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF991B1B),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (_currentState == 'feedback')
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: _handleContinue,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  _currentStepIndex == widget.node.steps.length - 1
                      ? 'Completar Leccion'
                      : 'Siguiente →',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAnswerCorrect == true
                      ? const Color(0xFF27AE60)
                      : const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                ),
              ),
            ),
          if (_currentState == 'answering' && !isQuizStep && !isMatchStep)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Builder(
                builder: (context) {
                  if (isChecklistQuizStep) {
                    final hasSelection = _selectedChecklistQuizIndices.isNotEmpty;
                    return ElevatedButton.icon(
                      onPressed: hasSelection
                          ? () => _handleChecklistQuizSubmit(step)
                          : null,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        _currentStepIndex == widget.node.steps.length - 1
                            ? 'Completar Lección'
                            : 'Siguiente →',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasSelection
                            ? const Color(0xFF27AE60)
                            : const Color(0xFFD1D5DB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: hasSelection ? 8 : 0,
                      ),
                    );
                  }
                  final isBlocked =
                      _stepHasChecklist(step) && !_checklistAllChecked;
                  return ElevatedButton.icon(
                    onPressed: isBlocked ? null : _handleContinue,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      _currentStepIndex == widget.node.steps.length - 1
                          ? 'Completar Leccion'
                          : 'Continuar',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBlocked
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                    ),
                  );
                },
              ),
            ),
          if (_currentState == 'loading')
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF27AE60),
                  strokeWidth: 4,
                ),
              ),
            ),

          // ── Cho FAB + burbuja de saludo ──────────────────────────────────
          Positioned(
            bottom: 90,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showChoGreeting)
                  GestureDetector(
                    onTap: () => setState(() => _showChoGreeting = false),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 220),
                      margin: const EdgeInsets.only(bottom: 8, right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '¡Qué rico, ${widget.node.title}! 🍽️\nSi necesitás ayuda, aquí estoy 👋',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ChoAssistantButton(
                  recipeId: widget.node.id,
                  recipeName: widget.node.title,
                  stepIndex: _currentStepIndex,
                  stepDescription: currentStepDesc,
                  elapsedSeconds: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Checklist card widget – interactive, tracks checked items per render
// ---------------------------------------------------------------------------
class _ChecklistCardWidget extends StatefulWidget {
  final String title;
  final List<String> items;
  final VoidCallback onAllChecked;

  const _ChecklistCardWidget({
    required this.title,
    required this.items,
    required this.onAllChecked,
  });

  @override
  State<_ChecklistCardWidget> createState() => _ChecklistCardWidgetState();
}

class _ChecklistCardWidgetState extends State<_ChecklistCardWidget> {
  late final List<bool> _checked;
  bool _allDone = false;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.items.length, false);
  }

  void _toggle(int i) {
    if (_allDone) return;
    setState(() {
      _checked[i] = !_checked[i];
      if (_checked.every((c) => c)) {
        _allDone = true;
        widget.onAllChecked();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _allDone ? const Color(0xFF27AE60) : const Color(0xFFE5E7EB),
          width: _allDone ? 2 : 1,
        ),
        boxShadow: _allDone
            ? [
                BoxShadow(
                  color: const Color(0xFF27AE60).withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title.isNotEmpty) ...[
            Text(
              widget.title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...List.generate(widget.items.length, (i) {
            final checked = _checked[i];
            return GestureDetector(
              onTap: () => _toggle(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: checked
                            ? const Color(0xFF27AE60)
                            : Colors.transparent,
                        border: Border.all(
                          color: checked
                              ? const Color(0xFF27AE60)
                              : const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: checked
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.4,
                          color: checked
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF1F2937),
                          decoration: checked
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: const Color(0xFF9CA3AF),
                        ),
                        child: Text(widget.items[i]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (_allDone) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF34D399)),
              ),
              child: Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '¡Tenés todo listo para empezar!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recipe builder card – ingredients fall into the scene in correct order
// ---------------------------------------------------------------------------

class _RecipeParticle {
  double x, y, vx, vy, opacity;
  _RecipeParticle(this.x, this.y, this.vx, this.vy) : opacity = 1.0;
}

class _RecipeBuilderCardWidget extends StatefulWidget {
  final String title;
  final String instruction;
  final String baseImage;
  final String finalImage;
  final String finishLabel;
  final List<Map<String, dynamic>> ingredients;
  final VoidCallback onCompleted;

  const _RecipeBuilderCardWidget({
    required this.title,
    required this.instruction,
    required this.baseImage,
    required this.finalImage,
    required this.finishLabel,
    required this.ingredients,
    required this.onCompleted,
  });

  @override
  State<_RecipeBuilderCardWidget> createState() =>
      _RecipeBuilderCardWidgetState();
}

class _RecipeBuilderCardWidgetState extends State<_RecipeBuilderCardWidget>
    with TickerProviderStateMixin {
  static const double _sceneH  = 240.0;
  static const double _ingSize = 54.0;

  // Sequential progress
  int  _settledCount = 0;
  int? _fallingIdx;

  bool _isMixing = false;
  bool _finished = false;

  // Per-ingredient fall (recreated each time)
  AnimationController? _fallCtrl;
  Animation<double>?   _fallYAnim;

  // Mixing animation
  late AnimationController _mixCtrl;

  // Particles for "salpicar"
  final List<_RecipeParticle> _particles = [];
  Timer? _particleTimer;

  final _sfx = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _mixCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _mixCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() { _isMixing = false; _finished = true; });
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _fallCtrl?.dispose();
    _mixCtrl.dispose();
    _particleTimer?.cancel();
    _sfx.dispose();
    super.dispose();
  }

  bool get _allSettled => _settledCount >= widget.ingredients.length;

  // ── Fall logic ─────────────────────────────────────────────────────────────

  void _handleIngredientTap() {
    if (_fallingIdx != null || _allSettled || _finished || _isMixing) return;
    _startFall(_settledCount);
  }

  void _startFall(int idx) {
    final ing      = widget.ingredients[idx];
    final posY     = (ing['posY'] as num?)?.toDouble() ?? 50.0;
    final animType = ing['animType']?.toString() ?? 'normal';
    final targetY  = (posY / 100.0) * _sceneH - _ingSize / 2;

    final Curve curve;
    final int   ms;
    switch (animType) {
      case 'rebote':
        curve = Curves.bounceOut; ms = 900; break;
      case 'salpicar':
        curve = Curves.easeIn;   ms = 500; break;
      default:
        curve = Curves.easeOut;  ms = 600;
    }

    _fallCtrl?.dispose();
    _fallCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: ms));
    _fallYAnim = Tween<double>(begin: -_ingSize, end: targetY)
        .animate(CurvedAnimation(parent: _fallCtrl!, curve: curve));

    setState(() => _fallingIdx = idx);
    _playSound('caer');

    _fallCtrl!.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        if (animType == 'salpicar') _spawnParticles(widget.ingredients[idx]);
        setState(() { _fallingIdx = null; _settledCount++; });
        if (_allSettled) _playSound('exito');
      }
    });
    _fallCtrl!.forward();
  }

  void _spawnParticles(Map<String, dynamic> ing) {
    final posX = (ing['posX'] as num?)?.toDouble() ?? 50.0;
    final posY = (ing['posY'] as num?)?.toDouble() ?? 50.0;
    final rand = math.Random();
    _particles.clear();
    for (int i = 0; i < 12; i++) {
      _particles.add(_RecipeParticle(
        posX, posY,
        (rand.nextDouble() - 0.5) * 6,
        -(rand.nextDouble() * 3 + 1),
      ));
    }
    _particleTimer?.cancel();
    _particleTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) { _particleTimer?.cancel(); return; }
      setState(() {
        for (final p in _particles) {
          p.x += p.vx * 0.5;
          p.y += p.vy * 0.5;
          p.vy += 0.3;
          p.opacity -= 0.04;
        }
        _particles.removeWhere((p) => p.opacity <= 0);
        if (_particles.isEmpty) _particleTimer?.cancel();
      });
    });
  }

  void _handleMix() {
    if (_isMixing) return;
    setState(() => _isMixing = true);
    _playSound('mezclar');
    _mixCtrl.forward(from: 0);
  }

  Future<void> _playSound(String type) async {
    try {
      const urls = {
        'caer':    'https://assets.mixkit.co/sfx/preview/mixkit-water-drop-1181.mp3',
        'mezclar': 'https://assets.mixkit.co/sfx/preview/mixkit-fast-sweep-transition-166.mp3',
        'exito':   'https://assets.mixkit.co/sfx/preview/mixkit-achievement-bell-600.mp3',
      };
      await _sfx.play(UrlSource(urls[type]!));
    } catch (_) {}
  }

  // ── Scene ──────────────────────────────────────────────────────────────────

  Widget _ingImage(Map<String, dynamic> ing, {bool falling = false, bool initial = false}) {
    String url;
    if (initial) {
      // Estado inicial antes de caer
      url = ing['initialImage']?.toString().isNotEmpty == true
          ? ing['initialImage'].toString()
          : (ing['settledImage']?.toString() ?? ing['imageUrl']?.toString() ?? '');
    } else if (falling) {
      // Cayendo
      url = ing['fallingImage']?.toString().isNotEmpty == true
          ? ing['fallingImage'].toString()
          : (ing['initialImage']?.toString() ?? ing['settledImage']?.toString() ?? ing['imageUrl']?.toString() ?? '');
    } else {
      // Asentado
      url = ing['settledImage']?.toString().isNotEmpty == true
          ? ing['settledImage'].toString()
          : (ing['imageUrl']?.toString() ?? '');
    }
    final emoji = ing['emoji']?.toString() ?? '';
    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: _ingSize, height: _ingSize, fit: BoxFit.contain,
        errorWidget: (_, __, ___) =>
            Text(emoji.isNotEmpty ? emoji : '🥘', style: const TextStyle(fontSize: 36)),
      );
    }
    return Text(emoji.isNotEmpty ? emoji : '🥘', style: const TextStyle(fontSize: 36));
  }

  List<Widget> _buildSettled(double sceneW) {
    if (_settledCount == 0) return [];

    final count = _finished ? widget.ingredients.length : _settledCount;
    final positioned = List.generate(count, (i) {
      final ing  = widget.ingredients[i];
      final posX = (ing['posX'] as num?)?.toDouble() ?? 50.0;
      final posY = (ing['posY'] as num?)?.toDouble() ?? 50.0;
      return Positioned(
        left: (posX / 100.0) * sceneW - _ingSize / 2,
        top:  (posY / 100.0) * _sceneH - _ingSize / 2,
        child: _ingImage(ing),
      );
    });

    if (_isMixing) {
      return [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _mixCtrl,
            builder: (_, child) {
              final t     = _mixCtrl.value;
              final angle = math.sin(t * math.pi) * 0.35;
              final blur  = math.sin(t * math.pi) * 5.0;
              return Transform.rotate(
                angle: angle,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: child,
                ),
              );
            },
            child: Stack(children: positioned),
          ),
        ),
      ];
    }

    return positioned;
  }

  Widget _scene(double sceneW) {
    return Container(
      width: sceneW, height: _sceneH,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Stack(
        children: [
          // Background image (base → final via AnimatedSwitcher)
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              child: _finished && widget.finalImage.isNotEmpty
                  ? CachedNetworkImage(
                      key: const ValueKey('f'),
                      imageUrl: widget.finalImage,
                      fit: BoxFit.cover,
                      width: double.infinity, height: double.infinity,
                    )
                  : widget.baseImage.isNotEmpty
                      ? CachedNetworkImage(
                          key: const ValueKey('b'),
                          imageUrl: widget.baseImage,
                          fit: BoxFit.cover,
                          width: double.infinity, height: double.infinity,
                        )
                      : const SizedBox.shrink(),
            ),
          ),

          // Settled ingredients (with mixing effect)
          ..._buildSettled(sceneW),

          // Falling ingredient
          if (_fallingIdx != null &&
              _fallYAnim != null &&
              _fallingIdx! < widget.ingredients.length)
            AnimatedBuilder(
              animation: _fallYAnim!,
              builder: (_, __) {
                final ing  = widget.ingredients[_fallingIdx!];
                final posX = (ing['posX'] as num?)?.toDouble() ?? 50.0;
                return Positioned(
                  left: (posX / 100.0) * sceneW - _ingSize / 2,
                  top:  _fallYAnim!.value,
                  child: _ingImage(ing, falling: true),
                );
              },
            ),

          // Splash particles
          ..._particles.map((p) => Positioned(
                left: (p.x / 100.0) * sceneW - 4,
                top:  (p.y / 100.0) * _sceneH - 4,
                child: Opacity(
                  opacity: p.opacity.clamp(0.0, 1.0),
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5E6C8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )),

          // Step counter badge
          if (!_finished)
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_settledCount / ${widget.ingredients.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Bottom action button ───────────────────────────────────────────────────

  Widget _buildAction() {
    // All settled → mezclar button
    if (_allSettled) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isMixing ? null : _handleMix,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isMixing
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  widget.finishLabel.isNotEmpty ? widget.finishLabel : '¡Mezclar!',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                ),
        ),
      );
    }

    // Next ingredient tap button
    final ing      = widget.ingredients[_settledCount];
    final emoji    = ing['emoji']?.toString() ?? '';
    final name     = ing['name']?.toString() ?? '';
    final falling  = _fallingIdx != null;

    return GestureDetector(
      onTap: falling ? null : _handleIngredientTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: falling ? const Color(0xFFF8FAFC) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: falling ? const Color(0xFFE2E8F0) : const Color(0xFF22C55E),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36, height: 36,
              child: _ingImage(ing, initial: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                falling ? 'Cayendo…' : '+ Agregar $name',
                style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: falling ? const Color(0xFF9CA3AF) : const Color(0xFF16A34A),
                ),
              ),
            ),
            if (!falling)
              const Icon(Icons.arrow_drop_down_rounded,
                  color: Color(0xFF22C55E), size: 22),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _finished ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
          width: _finished ? 2 : 1,
        ),
        boxShadow: _finished
            ? [const BoxShadow(color: Color(0x2A22C55E), blurRadius: 16, offset: Offset(0, 4))]
            : [const BoxShadow(color: Color(0x0A000000), blurRadius: 8,  offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title.isNotEmpty) ...[
            Text(widget.title,
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937))),
            const SizedBox(height: 4),
          ],
          if (widget.instruction.isNotEmpty) ...[
            Text(widget.instruction,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFF6B7280), height: 1.4)),
            const SizedBox(height: 12),
          ],

          // Scene with physics
          LayoutBuilder(builder: (_, c) => _scene(c.maxWidth)),
          const SizedBox(height: 12),

          // Tap button or finish button
          if (!_finished) _buildAction(),

          // Celebration
          if (_finished) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF34D399)),
              ),
              child: Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('¡Receta completada!',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: const Color(0xFF065F46))),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _LessonCompletionCelebrationDialog extends StatefulWidget {
  final int xpEarned;
  final int totalXP;
  final int level;
  final int streak;
  final bool isRepeat;
  final VoidCallback onContinue;

  const _LessonCompletionCelebrationDialog({
    required this.xpEarned,
    required this.totalXP,
    required this.level,
    required this.streak,
    required this.isRepeat,
    required this.onContinue,
  });

  @override
  State<_LessonCompletionCelebrationDialog> createState() =>
      _LessonCompletionCelebrationDialogState();
}

class _LessonCompletionCelebrationDialogState
    extends State<_LessonCompletionCelebrationDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _xpController;
  late final ConfettiController _confettiController;
  late final Animation<int> _xpCounter;
  bool _buttonPressed = false;

  int get _xpInCurrentLevel => widget.totalXP % 100;
  int get _xpNeededForLevel => 100;
  double get _levelProgress =>
      (_xpInCurrentLevel / _xpNeededForLevel).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: AppMotionDurations.celebrationEntrance,
    )..forward();

    _xpController = AnimationController(
      vsync: this,
      duration: AppMotionDurations.xpCount,
    );

    _xpCounter = IntTween(begin: 0, end: widget.xpEarned).animate(
      CurvedAnimation(parent: _xpController, curve: AppMotionCurves.entrance),
    );

    _confettiController = ConfettiController(
      duration: AppMotionDurations.confettiBurst,
    )..play();

    Future.delayed(AppMotionDurations.short, () {
      if (mounted) {
        _xpController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _xpController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isRepeat
        ? '¡Excelente trabajo!'
        : '¡Lección completada!';
    final subtitle = widget.isRepeat
        ? 'Volviste a superar el reto. Seguís sumando progreso.'
        : 'Resolviste esta lección como pro. ¡Seguí así!';

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _entryController,
              builder: (_, __) {
                return Opacity(
                  opacity: CurvedAnimation(
                    parent: _entryController,
                    curve: AppMotionCurves.feedback,
                  ).value,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xCC101827),
                          Color(0xB31F9D6A),
                          Color(0xCC0B1120),
                        ],
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 22,
                  gravity: 0.19,
                  emissionFrequency: 0.045,
                  maxBlastForce: 24,
                  minBlastForce: 10,
                  colors: const [
                    Color(0xFF22C55E),
                    Color(0xFFFFB703),
                    Color(0xFFFB7185),
                    Color(0xFF38BDF8),
                    Color(0xFFA78BFA),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (_, child) {
                  final bounce = AppMotionCurves.bounce.transform(
                    _entryController.value,
                  );
                  return Transform.scale(
                    scale: 0.9 + (0.1 * bounce),
                    child: Opacity(
                      opacity: _entryController.value,
                      child: child,
                    ),
                  );
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFDCFCE7),
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: Color(0xFF16A34A),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Color(0xFF16A34A),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedBuilder(
                                        animation: _xpCounter,
                                        builder: (_, __) {
                                          return Text(
                                            '+${_xpCounter.value} XP',
                                            style: GoogleFonts.poppins(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF16A34A),
                                              height: 1,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Nivel ${widget.level} · ${widget.streak > 0 ? 'Racha ${widget.streak}' : 'Nueva racha'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Progreso hacia el siguiente nivel',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: _levelProgress,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF22C55E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_xpInCurrentLevel/$_xpNeededForLevel XP en este nivel',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _AnimatedContinueButton(
                          pressed: _buttonPressed,
                          onPressedState: (pressed) {
                            if (mounted) {
                              setState(() => _buttonPressed = pressed);
                            }
                          },
                          onTap: widget.onContinue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedContinueButton extends StatelessWidget {
  final bool pressed;
  final ValueChanged<bool> onPressedState;
  final VoidCallback onTap;

  const _AnimatedContinueButton({
    required this.pressed,
    required this.onPressedState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressedState(true),
      onTapCancel: () => onPressedState(false),
      onTapUp: (_) => onPressedState(false),
      onTap: onTap,
      child: AnimatedScale(
        duration: AppMotionDurations.quick,
        curve: AppMotionCurves.tap,
        scale: pressed ? AppMotionValues.pressedScale : 1,
        child: AnimatedContainer(
          duration: AppMotionDurations.quick,
          curve: AppMotionCurves.tap,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF16A34A,
                ).withValues(alpha: pressed ? 0.2 : 0.38),
                blurRadius: pressed ? 10 : 18,
                offset: Offset(0, pressed ? 5 : 10),
              ),
            ],
          ),
          child: Text(
            'Continuar',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUTTING BOARD CARD
// ═══════════════════════════════════════════════════════════════════════════════
//
// Data: { instruction, baseImage, frames: [{imageUrl, tapX, tapY, tapRadius}] }
// Mechanic:
//   - Shows baseImage as background (cutting board).
//   - Overlays the current frame (object to cut).
//   - Frame 0: pulsing hint circle shows where to tap first.
//   - User taps inside the valid zone → frame advances + cut flash.
//   - User taps outside → red "miss" flash, no advance.
//   - After all frames: completion animation + onCompleted().

class _CuttingBoardCardWidget extends StatefulWidget {
  final String instruction;
  final String baseImage;
  final List<Map<String, dynamic>> frames;
  final VoidCallback onCompleted;

  const _CuttingBoardCardWidget({
    required this.instruction,
    required this.baseImage,
    required this.frames,
    required this.onCompleted,
  });

  @override
  State<_CuttingBoardCardWidget> createState() =>
      _CuttingBoardCardWidgetState();
}

class _CuttingBoardCardWidgetState extends State<_CuttingBoardCardWidget>
    with TickerProviderStateMixin {
  int _frameIdx = 0;
  bool _finished = false;
  bool _missFlash = false;
  bool _cutFlash = false;

  late final AnimationController _hintCtrl;
  late final Animation<double> _hintScale;

  late AnimationController _frameCtrl;
  late Animation<double> _frameFade;

  late final AnimationController _doneCtrl;
  late final Animation<double> _doneScale;

  AudioPlayer? _sfx;

  @override
  void initState() {
    super.initState();

    _hintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _hintScale = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _hintCtrl, curve: Curves.easeInOut),
    );

    _frameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _frameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _frameCtrl, curve: Curves.easeOut),
    );
    _frameCtrl.value = 1.0;

    _doneCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _doneScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _doneCtrl, curve: Curves.elasticOut),
    );

    _sfx = AudioPlayer();
  }

  @override
  void dispose() {
    _hintCtrl.dispose();
    _frameCtrl.dispose();
    _doneCtrl.dispose();
    _sfx?.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _currentFrame => widget.frames[_frameIdx];

  Future<void> _playSound(String url) async {
    try {
      await _sfx?.play(UrlSource(url));
    } catch (_) {}
  }

  Future<void> _handleTap(Offset localPos, Size sceneSize) async {
    if (_finished) return;

    final frame = _currentFrame;
    final tapX = (frame['tapX'] as num?)?.toDouble() ?? 50.0;
    final tapY = (frame['tapY'] as num?)?.toDouble() ?? 50.0;
    final tapRadius = (frame['tapRadius'] as num?)?.toDouble() ?? 12.0;

    final zoneX = tapX / 100.0 * sceneSize.width;
    final zoneY = tapY / 100.0 * sceneSize.height;
    final radiusPx = tapRadius / 100.0 * sceneSize.width;

    final dx = localPos.dx - zoneX;
    final dy = localPos.dy - zoneY;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist <= radiusPx) {
      await _onValidTap();
    } else {
      _onMiss();
    }
  }

  Future<void> _onValidTap() async {
    _playSound(
        'https://assets.mixkit.co/active_storage/sfx/2571/2571-preview.mp3');

    setState(() => _cutFlash = true);
    await Future.delayed(const Duration(milliseconds: 120));

    final nextIdx = _frameIdx + 1;
    if (nextIdx >= widget.frames.length) {
      setState(() {
        _cutFlash = false;
        _finished = true;
      });
      _hintCtrl.stop();
      _doneCtrl.forward();
      _playSound(
          'https://assets.mixkit.co/active_storage/sfx/1435/1435-preview.mp3');
      widget.onCompleted();
    } else {
      _frameCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _frameIdx = nextIdx;
          _cutFlash = false;
        });
        _frameCtrl.forward();
      });
    }
  }

  void _onMiss() {
    setState(() => _missFlash = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _missFlash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.instruction.isNotEmpty) ...[
            Text(
              widget.instruction,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Scene
          LayoutBuilder(builder: (context, constraints) {
            final sceneW = constraints.maxWidth;
            final sceneH = sceneW * 0.6;

            return GestureDetector(
              onTapDown: _finished
                  ? null
                  : (det) =>
                      _handleTap(det.localPosition, Size(sceneW, sceneH)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: sceneW,
                  height: sceneH,
                  child: Stack(
                    children: [
                      // Base image
                      if (widget.baseImage.isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            widget.baseImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: const Color(0xFFF3F4F6)),
                          ),
                        )
                      else
                        Positioned.fill(
                          child: Container(color: const Color(0xFFD4A96A)),
                        ),

                      // Current frame overlay
                      if (!_finished)
                        Positioned.fill(
                          child: FadeTransition(
                            opacity: _frameFade,
                            child: Image.network(
                              _currentFrame['imageUrl']?.toString() ?? '',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                          ),
                        ),

                      // Hint pulse — only on first frame before any tap
                      if (!_finished && _frameIdx == 0)
                        _buildHintCircle(sceneW, sceneH),

                      // Cut flash
                      if (_cutFlash)
                        Positioned.fill(
                          child:
                              Container(color: Colors.white.withOpacity(0.5)),
                        ),

                      // Miss flash
                      if (_missFlash)
                        Positioned.fill(
                          child: Container(color: Colors.red.withOpacity(0.25)),
                        ),

                      // Progress badge
                      if (!_finished)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_frameIdx}/${widget.frames.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                      // Completion overlay
                      if (_finished)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF22C55E).withOpacity(0.85),
                                  const Color(0xFF16A34A).withOpacity(0.95),
                                ],
                              ),
                            ),
                            child: Center(
                              child: ScaleTransition(
                                scale: _doneScale,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('✅',
                                        style: TextStyle(fontSize: 48)),
                                    const SizedBox(height: 8),
                                    Text(
                                      '¡Perfecto corte!',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
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
          }),

          const SizedBox(height: 10),

          // Frame progress dots
          if (!_finished)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.frames.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _frameIdx ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i < _frameIdx
                        ? const Color(0xFF22C55E)
                        : i == _frameIdx
                            ? const Color(0xFF15803D)
                            : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHintCircle(double sceneW, double sceneH) {
    final frame = widget.frames[0];
    final tapX = (frame['tapX'] as num?)?.toDouble() ?? 50.0;
    final tapY = (frame['tapY'] as num?)?.toDouble() ?? 50.0;
    final tapRadius = (frame['tapRadius'] as num?)?.toDouble() ?? 12.0;

    final cx = tapX / 100.0 * sceneW;
    final cy = tapY / 100.0 * sceneH;
    final r = tapRadius / 100.0 * sceneW;

    return Positioned(
      left: cx - r,
      top: cy - r,
      width: r * 2,
      height: r * 2,
      child: AnimatedBuilder(
        animation: _hintScale,
        builder: (_, __) => Transform.scale(
          scale: _hintScale.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.35),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text('👆', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}
