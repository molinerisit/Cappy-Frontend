import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/api_service.dart';
import '../../../core/models/learning_node.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/progress_provider.dart';
import '../widgets/lesson_progress_header.dart';
import '../widgets/question_card.dart';
import '../widgets/option_card.dart';
import '../widgets/feedback_bar.dart';

/// Estados de la pantalla de lección
enum LessonState { loading, answering, showingFeedback, completed }

/// Pantalla de lección completamente refactorizada tipo Duolingo
/// - Flujo: Seleccionar → Feedback inmediato → CTA único → Avanzar
/// - Sin dialogs ni alerts, solo feedback integrado
/// - Animaciones en cada interacción
/// - Experiencia lúdica y adictiva
class LessonFlowScreenDuolingo extends StatefulWidget {
  final LearningNode node;
  final VoidCallback? onComplete;

  const LessonFlowScreenDuolingo({
    super.key,
    required this.node,
    this.onComplete,
  });

  @override
  State<LessonFlowScreenDuolingo> createState() =>
      _LessonFlowScreenDuolingoState();
}

class _LessonFlowScreenDuolingoState extends State<LessonFlowScreenDuolingo>
    with TickerProviderStateMixin {
  late int _currentStepIndex;
  int? _selectedAnswerIndex;
  bool? _isAnswerCorrect;
  late AnimationController _shakeController;
  LessonState _state = LessonState.answering;

  @override
  void initState() {
    super.initState();
    _currentStepIndex = 0;
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// Maneja la selección de una opción
  /// - Verifica inmediatamente si es correcta
  /// - Muestra feedback visual
  void _handleOptionSelected(int answerIndex) {
    if (_state != LessonState.answering || _selectedAnswerIndex != null) {
      return;
    }

    setState(() {
      _selectedAnswerIndex = answerIndex;
    });

    // Simular verificación (en producción, este sería server-side)
    final step = widget.node.steps[_currentStepIndex];
    final selectedOption = (step.options ?? [])[answerIndex];
    final isCorrect = selectedOption == step.correctAnswer;

    if (!isCorrect) {
      // Si es incorrecto, hacer shake animation
      _shakeController.forward().then((_) {
        _shakeController.reset();
      });
    }

    // Esperar un poco antes de mostrar feedback
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isAnswerCorrect = isCorrect;
          _state = LessonState.showingFeedback;
        });
      }
    });
  }

  /// Continua al siguiente paso o completa la lección
  void _handleContinue() {
    final isLastStep = _currentStepIndex == widget.node.steps.length - 1;

    if (isLastStep) {
      _completeLessonNode();
    } else {
      // Transición al siguiente paso
      setState(() {
        _currentStepIndex++;
        _selectedAnswerIndex = null;
        _isAnswerCorrect = null;
        _state = LessonState.answering;
      });
    }
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

  /// Completa el nodo en el servidor
  Future<void> _completeLessonNode() async {
    setState(() => _state = LessonState.loading);

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

      // Mostrar modal de celebración tipo Duolingo
      _showCompletionCelebration(result);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );

      setState(() => _state = LessonState.answering);
    }
  }

  /// Muestra el modal de celebración
  void _showCompletionCelebration(Map<String, dynamic> result) {
    final isRepeat = result['isRepeat'] ?? false;
    final title = isRepeat ? '¡Bien hecho de nuevo!' : '¡Excelente!';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Confeti emoji
            const Text('🎉', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),

            // Card de celebración
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF27AE60),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // XP Ganado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '+',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      Text(
                        '${result['xpEarned'] ?? 0}',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF6B35),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'XP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botón continuar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context, true); // Close lesson screen
                        widget.onComplete?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.node.steps[_currentStepIndex];
    final options = _sanitizeOptions(step.options);
    final isQuizStep = options.length >= 2;
    final questionText = _firstNonEmpty([
      step.question,
      step.title,
      step.description,
      step.instruction,
    ], 'Contenido de la leccion');
    final infoText = _firstNonEmpty([
      step.instruction,
      step.description,
      step.feedback,
    ], '');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          color: const Color(0xFF1F2937),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Contenido principal
          CustomScrollView(
            slivers: [
              // Header de progreso
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.white,
                elevation: 0,
                expandedHeight: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: SizedBox(
                    height: 80,
                    child: LessonProgressHeader(
                      currentStep: _currentStepIndex + 1,
                      totalSteps: widget.node.steps.length,
                      lessonTitle: widget.node.title,
                    ),
                  ),
                ),
              ),

              // Contenido
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 180),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Pregunta
                    QuestionCard(
                      question: questionText,
                      subtitle: isQuizStep
                          ? 'Selecciona la opción correcta'
                          : null,
                      imageUrl: step.image,
                    ),

                    if (!isQuizStep) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          infoText.isNotEmpty
                              ? infoText
                              : 'Este paso no tiene contenido adicional.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B5563),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Opciones de respuesta en Grid (2 columnas)
                    if (isQuizStep)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                        children: List.generate(options.length, (index) {
                          final option = options[index];
                          final isSelected = _selectedAnswerIndex == index;
                          final isCorrectAnswer = option == step.correctAnswer;

                          // Determinar estado de la opción
                          OptionState optionState;
                          if (_state == LessonState.answering) {
                            optionState = isSelected
                                ? OptionState.selected
                                : OptionState.idle;
                          } else if (_state == LessonState.showingFeedback) {
                            if (isCorrectAnswer) {
                              optionState = OptionState.correct;
                            } else if (isSelected &&
                                _isAnswerCorrect == false) {
                              optionState = OptionState.incorrect;
                            } else {
                              optionState = OptionState.disabled;
                            }
                          } else {
                            optionState = OptionState.disabled;
                          }

                          // Aplicar shake si es incorrecta y seleccionada
                          Widget optionCardWidget = OptionCard(
                            text: option,
                            isSelected: isSelected,
                            state: optionState,
                            onTap:
                                _state == LessonState.answering &&
                                    _selectedAnswerIndex == null
                                ? () => _handleOptionSelected(index)
                                : null,
                            isEnabled:
                                _state == LessonState.answering &&
                                _selectedAnswerIndex == null,
                          );

                          // Envolver con shake si es incorrecta
                          if (isSelected && _isAnswerCorrect == false) {
                            optionCardWidget = _ShakeWidget(
                              controller: _shakeController,
                              child: optionCardWidget,
                            );
                          }

                          return optionCardWidget;
                        }),
                      ),
                  ]),
                ),
              ),
            ],
          ),

          // Feedback bar flotante
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FeedbackBar(
              type: _isAnswerCorrect == true
                  ? FeedbackType.correct
                  : _isAnswerCorrect == false
                  ? FeedbackType.incorrect
                  : FeedbackType.neutral,
              message: _getfeedbackMessage(),
              ctaText: _currentStepIndex == widget.node.steps.length - 1
                  ? 'Completar'
                  : 'Siguiente',
              onCTA: _handleContinue,
              show: _state == LessonState.showingFeedback,
            ),
          ),

          // Loading indicator
          if (_state == LessonState.loading)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF27AE60)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getfeedbackMessage() {
    if (_isAnswerCorrect == null) {
      return '';
    }

    if (_isAnswerCorrect!) {
      return '¡Excelente! Respuesta correcta. ¡Sigue así!';
    } else {
      return 'Casi lo tienes. La respuesta correcta es la que está marcada en verde.';
    }
  }
}

/// Widget para animar un shake (wobble) cuando la respuesta es incorrecta
class _ShakeWidget extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const _ShakeWidget({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final shake = math.sin(controller.value * 4 * 3.14159) * 10;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: child,
    );
  }
}
