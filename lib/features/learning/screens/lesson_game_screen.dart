import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/api_service.dart';
import '../../../core/models/learning_node.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../widgets/step_timer_widget.dart';

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
  String _currentState = 'answering'; // answering, feedback, loading
  late Completer<void> _celebrationCompleter;

  @override
  void initState() {
    super.initState();
    _currentStepIndex = 0;
    _celebrationCompleter = Completer<void>();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _audioPlayer = AudioPlayer();
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
      _shakeController.forward().then((_) => _shakeController.reset());
    }

    Future.delayed(const Duration(milliseconds: 600), () {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Respuesta incorrecta. Intenta de nuevo.'),
        ),
      );
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
      if (totalXP != null && level != null) {
        context.read<AuthProvider>().updateXPAndLevel(totalXP, level);
      }

      // Update progress in ProgressProvider
      context.read<ProgressProvider>().updateFromNodeCompletion(result);

      // Remove loading overlay
      setState(() => _currentState = 'answering');

      // Reset celebration completer for this celebration
      _celebrationCompleter = Completer<void>();

      // Play success sound
      await _playSuccessSound();

      // Show celebration dialog and wait for user to press button
      await _showCelebration(result);
      if (!mounted) return;

      // Close lesson and return to path progression (node tree)
      Navigator.of(context).pop(true); // Only pop one route
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _currentState = 'answering');
    }
  }

  Future<void> _showCelebration(Map<String, dynamic> result) async {
    final isRepeat = result['isRepeat'] ?? false;
    final title = isRepeat ? '¡Bien hecho de nuevo!' : '¡Leccion Completada!';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 100)),
              const SizedBox(height: 30),
              Container(
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
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF27AE60),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                          '${result['xpEarned'] ?? 100}',
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
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          if (!_celebrationCompleter.isCompleted) {
                            _celebrationCompleter.complete();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Continuar',
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
            ],
          ),
        ),
      ),
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
                  const Icon(Icons.timer, color: Color(0xFFFF6B35), size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    'Timer',
                    style: TextStyle(
                      color: Color(0xFFFF6B35),
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
            content['imageUrl']?.toString() ??
            content['media']?.toString() ??
            card['image']?.toString() ??
            card['media']?.toString();

        if (cardType == 'list' && listItems.isNotEmpty) {
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
                  ...listItems
                      .map((item) => item?.toString() ?? '')
                      .where((item) => item.trim().isNotEmpty)
                      .map(
                        (item) => Padding(
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
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          );
          continue;
        }

        if (cardBody.isEmpty && cardImage == null) {
          continue;
        }

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
                if (cardImage != null && cardImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      cardImage,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        width: double.infinity,
                        color: const Color(0xFFF3F4F6),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                if (cardTitle.isNotEmpty) ...[
                  if (cardImage != null && cardImage.isNotEmpty)
                    const SizedBox(height: 12),
                  Text(
                    cardTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
                if (cardBody.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    cardBody,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF4B5563),
                      height: 1.4,
                    ),
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
          iconColor: const Color(0xFFFF6B35),
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
    final isQuizStep = options.length >= 2;
    final contentCards = _buildContentCards(step, excludeQuiz: isQuizStep);
    final questionText = _firstNonEmpty([
      step.question,
      step.title,
      step.description,
      step.instruction,
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
                          child: Image.network(
                            step.image!,
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 240,
                              width: double.infinity,
                              color: const Color(0xFFF3F4F6),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                size: 32,
                                color: Color(0xFF9CA3AF),
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
                    if (step.instruction.isNotEmpty)
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
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.9,
                        children: List.generate(options.length, (index) {
                          final option = options[index];
                          final isSelected = _selectedAnswerIndex == index;
                          final isCorrectAnswer = option == step.correctAnswer;

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
                            duration: const Duration(milliseconds: 150),
                            child: GestureDetector(
                              onTap:
                                  _currentState == 'answering' &&
                                      _selectedAnswerIndex == null
                                  ? () => _handleOptionSelected(index)
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
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
                                        ).withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (iconData != null)
                                      Icon(iconData, size: 40, color: iconColor)
                                    else
                                      Text(
                                        [
                                          '🌮',
                                          '🍕',
                                          '🍝',
                                          '🍜',
                                          '🥘',
                                          '🍲',
                                        ][index % 6],
                                        style: const TextStyle(fontSize: 40),
                                      ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        option,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
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
                                    12;
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
                    if (!isQuizStep && contentCards.isEmpty)
                      ..._buildContentCards(step),
                  ]),
                ),
              ),
            ],
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
                      : const Color(0xFFFF6B35),
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
              child: ElevatedButton.icon(
                onPressed: _handleContinue,
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
                  backgroundColor: const Color(0xFF27AE60),
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
