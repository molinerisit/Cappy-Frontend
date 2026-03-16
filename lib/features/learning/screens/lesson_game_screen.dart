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
  late AnimationController _shakeController;
  late final AudioPlayer _audioPlayer;
  late final LivesService _livesService;
  String _currentState = 'answering'; // answering, feedback, loading
  bool _isApplyingLifePenalty = false;
  int _currentLives = 3;
  bool _checklistAllChecked = false;

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
    if (isQuizStep && _isAnswerCorrect != true) {
      if (!mounted) return;
      // User already sees visual feedback - no need for snackbar
      setState(() {
        _selectedAnswerIndex = null;
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
      step.cards?.any((c) => c['type'] == 'checklist') ?? false;

  List<Widget> _buildContentCards(NodeStep step, {bool excludeQuiz = false}) {
    final cards = <Widget>[];
    final hasCards = step.cards != null && step.cards!.isNotEmpty;

    if (hasCards) {
      for (final card in step.cards!) {
        final cardType = card['type']?.toString();
        if (excludeQuiz && cardType == 'quiz') {
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
    final contentCards = _buildContentCards(step, excludeQuiz: isQuizStep);
    final showStepInstruction =
        step.instruction.isNotEmpty &&
        !_stepInstructionIsDuplicatedByCards(step);
    final questionText = _firstNonEmpty([
      step.question,
      step.title,
      step.description,
    ], 'Contenido de la leccion');

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
                    Text(
                      questionText,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                        height: 1.4,
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
                    const SizedBox(height: 40),
                    if (contentCards.isNotEmpty) ...contentCards,
                    if (isQuizStep)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.0,
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
                    if (!isQuizStep && contentCards.isEmpty)
                      ..._buildContentCards(step),
                  ]),
                ),
              ),
            ],
          ),
          if (_currentState == 'feedback' && isQuizStep)
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
          if (_currentState == 'answering' && !isQuizStep)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Builder(
                builder: (context) {
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
