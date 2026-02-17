import 'package:flutter/material.dart';

class LessonFlowScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final String lessonType; // 'recipe', 'culture', 'skill'
  final List<dynamic> steps;

  const LessonFlowScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonType,
    required this.steps,
  });

  @override
  State<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends State<LessonFlowScreen> {
  late PageController _pageController;
  int _currentStep = 0;
  late List<dynamic> steps;
  final Map<String, bool> _completedSteps = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    steps = widget.steps;
    _initializeSteps();
  }

  void _initializeSteps() {
    for (var i = 0; i < steps.length; i++) {
      _completedSteps[steps[i]['id'] ?? '$i'] = false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep < steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Última lección - guardar progreso
      await _completeLesson();
    }
  }

  Future<void> _completeLesson() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Llamar API para guardar progreso
      // await ApiService.completeLesson(widget.lessonId, xpEarned: 100);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Lección completada! +100 XP')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _markStepCompleted(String stepId) {
    setState(() {
      _completedSteps[stepId] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('¿Dejar esta lección?'),
                content: const Text(
                  'Tu progreso será guardado automáticamente.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Continuar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Salir'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.lessonTitle),
          backgroundColor: Colors.orange.shade700,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              itemBuilder: (context, index) {
                if (index >= steps.length) return const SizedBox();
                return _buildStepWidget(steps[index], index);
              },
            ),
            // Progress bar superior mejorada
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / steps.length,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(Colors.orange.shade600),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Progreso: ${_currentStep + 1}/${steps.length} pasos',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${((_currentStep + 1) / steps.length * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón atrás
                if (_currentStep > 0)
                  ElevatedButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Atrás'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  )
                else
                  const SizedBox(width: 80),

                // Indicador de paso
                Text(
                  '${_currentStep + 1} / ${steps.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Botón siguiente/completar
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _nextStep,
                  icon: Icon(
                    _currentStep == steps.length - 1
                        ? Icons.check_circle
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    _currentStep == steps.length - 1
                        ? 'Completar'
                        : 'Siguiente',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepWidget(dynamic step, int index) {
    final stepId = step['id'] ?? '$index';
    final cards = step['cards'] as List? ?? [];

    // Si el paso tiene tarjetas, mostrar CardStep
    if (cards.isNotEmpty) {
      return _CardStep(
        title: step['title'] ?? 'Paso ${index + 1}',
        description: step['description'] ?? '',
        cards: cards,
        onCompleted: () => _markStepCompleted(stepId),
      );
    }

    final stepType = step['type'] ?? 'text';

    switch (stepType) {
      case 'ingredients':
        return _IngredientsStep(
          ingredients: step['ingredients'] ?? [],
          onCompleted: () => _markStepCompleted(stepId),
        );

      case 'multiple_choice':
        return _MultipleChoiceStep(
          question: step['question'] ?? 'Pregunta',
          options: step['options'] ?? [],
          onCompleted: () => _markStepCompleted(stepId),
          feedbackCorrect: step['feedback']?['correct'],
          feedbackIncorrect: step['feedback']?['incorrect'],
        );

      case 'video':
        return _VideoStep(
          videoUrl: step['videoUrl'] ?? '',
          title: step['title'] ?? 'Video',
          description: step['instruction'] ?? '',
          onCompleted: () => _markStepCompleted(stepId),
        );

      case 'audio':
        return _AudioStep(
          audioUrl: step['audioUrl'] ?? '',
          title: step['title'] ?? 'Audio',
          transcript: step['instruction'] ?? '',
          onCompleted: () => _markStepCompleted(stepId),
        );

      case 'image':
        return _ImageStep(
          imageUrl: step['imageUrl'] ?? '',
          title: step['title'] ?? 'Imagen',
          caption: step['instruction'] ?? '',
          onCompleted: () => _markStepCompleted(stepId),
        );

      case 'text':
      default:
        return _TextStep(
          title: step['title'] ?? 'Paso ${index + 1}',
          content: step['instruction'] ?? step['content'] ?? '',
          imageUrl: step['imageUrl'],
          onCompleted: () => _markStepCompleted(stepId),
        );
    }
  }
}

// ==========================================
// CARD STEP: Tarjetas interactivas estilo Duolingo
// ==========================================
class _CardStep extends StatefulWidget {
  final String title;
  final String description;
  final List<dynamic> cards;
  final VoidCallback onCompleted;

  const _CardStep({
    required this.title,
    required this.description,
    required this.cards,
    required this.onCompleted,
  });

  @override
  State<_CardStep> createState() => _CardStepState();
}

class _CardStepState extends State<_CardStep> {
  late PageController _cardController;
  int _currentCard = 0;
  late List<bool> _completedCards;

  @override
  void initState() {
    super.initState();
    _cardController = PageController();
    _completedCards = List.filled(widget.cards.length, false);
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  bool get _allCardsCompleted => _completedCards.every((c) => c);

  void _markCardCompleted(int index) {
    setState(() => _completedCards[index] = true);

    // Si todas completadas, marcar paso como completado en 500ms
    if (_allCardsCompleted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onCompleted();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del paso
          Text(
            widget.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          if (widget.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.description),
          ],
          const SizedBox(height: 24),

          // Indicador de tarjeta dentro del paso
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Text(
                  'Tarjeta ${_currentCard + 1}/${widget.cards.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                const Spacer(),
                for (int i = 0; i < widget.cards.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _completedCards[i]
                            ? Colors.green.shade400
                            : i == _currentCard
                            ? Colors.orange.shade400
                            : Colors.grey.shade300,
                      ),
                      child: Center(
                        child: _completedCards[i]
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            : Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Tarjetas
          SizedBox(
            height: 400,
            child: PageView.builder(
              controller: _cardController,
              pageSnapping: true,
              onPageChanged: (index) {
                setState(() => _currentCard = index);
              },
              itemCount: widget.cards.length,
              itemBuilder: (context, index) {
                final card = widget.cards[index] as Map? ?? {};
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildCardWidget(
                    card,
                    index,
                    () => _markCardCompleted(index),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Botones de navegación
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentCard > 0)
                ElevatedButton.icon(
                  onPressed: () => _cardController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                )
              else
                const SizedBox(width: 100),
              if (_currentCard < widget.cards.length - 1)
                ElevatedButton.icon(
                  onPressed: () => _cardController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Siguiente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          if (_allCardsCompleted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¡Excelente! Completaste todas las tarjetas.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
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

  Widget _buildCardWidget(
    Map<dynamic, dynamic> card,
    int index,
    VoidCallback onCompleted,
  ) {
    final cardType = card['type'] ?? 'text';
    final content = card['content'] as Map? ?? {};
    final isCompleted = _completedCards[index];

    switch (cardType) {
      case 'text':
        return _buildTextCard(
          content['title'] ?? 'Tarjeta de texto',
          content['text'] ?? '',
          isCompleted,
          onCompleted,
        );
      case 'image':
        return _buildImageCard(
          content['title'] ?? 'Tarjeta de imagen',
          content['imageUrl'] ?? '',
          isCompleted,
          onCompleted,
        );
      case 'quiz':
        return _buildQuizCard(
          content['question'] ?? '¿Pregunta?',
          content['options'] as List? ?? [],
          isCompleted,
          onCompleted,
        );
      case 'fill-blank':
        return _buildFillBlankCard(
          content['sentence'] ?? '_____',
          content['answers'] as List? ?? [],
          isCompleted,
          onCompleted,
        );
      case 'audio':
        return _buildAudioCard(
          content['audioUrl'] ?? '',
          content['title'] ?? 'Audio',
          isCompleted,
          onCompleted,
        );
      case 'video':
        return _buildVideoCard(
          content['videoUrl'] ?? '',
          content['title'] ?? 'Video',
          isCompleted,
          onCompleted,
        );
      default:
        return _buildErrorCard();
    }
  }

  Widget _buildTextCard(
    String title,
    String text,
    bool isCompleted,
    VoidCallback onCompleted,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: isCompleted ? Colors.green : Colors.orange,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📝 $title',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(text, style: const TextStyle(fontSize: 14, height: 1.6)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCompleted ? null : onCompleted,
                icon: Icon(isCompleted ? Icons.check : Icons.done_all),
                label: Text(isCompleted ? 'Completado' : 'Entendido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(
    String title,
    String imageUrl,
    bool isCompleted,
    VoidCallback onCompleted,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: isCompleted ? Colors.green : Colors.orange,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  '🖼️ $title',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey.shade300,
                          child: const Center(child: Icon(Icons.broken_image)),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCompleted ? null : onCompleted,
                icon: Icon(isCompleted ? Icons.check : Icons.done_all),
                label: Text(isCompleted ? 'Completado' : 'Entendido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(
    String question,
    List<dynamic> options,
    bool isCompleted,
    VoidCallback onCompleted,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        int? selectedIndex;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(
                color: isCompleted ? Colors.green : Colors.orange,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '❓ $question',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(options.length, (i) {
                      final option = options[i] as Map? ?? {};
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          color: selectedIndex == i
                              ? Colors.orange.shade100
                              : Colors.grey.shade50,
                          child: ListTile(
                            onTap: isCompleted
                                ? null
                                : () => setState(() => selectedIndex = i),
                            trailing: Radio<int?>(
                              value: i,
                              groupValue: selectedIndex,
                              onChanged: isCompleted
                                  ? null
                                  : (v) => setState(() => selectedIndex = v),
                            ),
                            title: Text(option['text'] ?? 'Opción'),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isCompleted || selectedIndex == null
                        ? null
                        : () {
                            final correct =
                                (options[selectedIndex!] as Map?)?['correct'] ??
                                false;
                            if (correct) {
                              onCompleted();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ Respuesta incorrecta'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('Verificar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
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

  Widget _buildFillBlankCard(
    String sentence,
    List<dynamic> answers,
    bool isCompleted,
    VoidCallback onCompleted,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: isCompleted ? Colors.green : Colors.orange,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✏️ Completa la frase',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  sentence,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selecciona la respuesta correcta:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final ans in answers)
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Respondiste: $ans')),
                          );
                          onCompleted();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: Text(ans.toString()),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioCard(
    String audioUrl,
    String title,
    bool isCompleted,
    VoidCallback onCompleted,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: isCompleted ? Colors.green : Colors.orange,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  '🎧 $title',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                const Icon(
                  Icons.play_circle_outline,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Audio disponible',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCompleted ? null : onCompleted,
                icon: Icon(isCompleted ? Icons.check : Icons.done_all),
                label: Text(isCompleted ? 'Completado' : 'Escuchado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(
    String videoUrl,
    String title,
    bool isCompleted,
    VoidCallback onCompleted,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: isCompleted ? Colors.green : Colors.orange,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  '🎥 $title',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                const Icon(
                  Icons.play_circle_outline,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Video disponible',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCompleted ? null : onCompleted,
                icon: Icon(isCompleted ? Icons.check : Icons.done_all),
                label: Text(isCompleted ? 'Completado' : 'Visto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Tipo de tarjeta no soportado',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// INGREDIENT STEP (Checklist)
// ==========================================
class _IngredientsStep extends StatefulWidget {
  final List<dynamic> ingredients;
  final VoidCallback onCompleted;

  const _IngredientsStep({
    required this.ingredients,
    required this.onCompleted,
  });

  @override
  State<_IngredientsStep> createState() => _IngredientsStepState();
}

class _IngredientsStepState extends State<_IngredientsStep> {
  late Map<int, bool> _checkedItems;

  @override
  void initState() {
    super.initState();
    _checkedItems = {
      for (var i = 0; i < widget.ingredients.length; i++) i: false,
    };
  }

  bool get _allChecked => _checkedItems.values.every((v) => v);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📑 Ingredientes',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          const Text(
            'Verifica que tengas todos estos ingredientes:',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ...List.generate(widget.ingredients.length, (index) {
            final ing = widget.ingredients[index];
            return CheckboxListTile(
              value: _checkedItems[index] ?? false,
              onChanged: (val) {
                setState(() => _checkedItems[index] = val ?? false);
                if (_allChecked) {
                  Future.delayed(const Duration(milliseconds: 400), () {
                    widget.onCompleted();
                  });
                }
              },
              title: Text(
                '${ing['name'] ?? 'Ingrediente'} ${ing['quantity'] ?? ''} ${ing['unit'] ?? ''}',
                style: const TextStyle(fontSize: 16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.grey, width: 0.5),
              ),
            );
          }),
          const SizedBox(height: 20),
          if (_allChecked)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text(
                    '¡Excelente! Todos los ingredientes listos.',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// MULTIPLE CHOICE STEP
// ==========================================
class _MultipleChoiceStep extends StatefulWidget {
  final String question;
  final List<dynamic> options;
  final VoidCallback onCompleted;
  final String? feedbackCorrect;
  final String? feedbackIncorrect;

  const _MultipleChoiceStep({
    required this.question,
    required this.options,
    required this.onCompleted,
    this.feedbackCorrect,
    this.feedbackIncorrect,
  });

  @override
  State<_MultipleChoiceStep> createState() => _MultipleChoiceStepState();
}

class _MultipleChoiceStepState extends State<_MultipleChoiceStep> {
  String? _selectedAnswer;
  bool? _isCorrect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '❓ Pregunta',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              widget.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(widget.options.length, (index) {
            final option = widget.options[index];
            final optionId = option['id'] ?? '$index';
            final isSelected = _selectedAnswer == optionId;
            final isCorrectAnswer = option['isCorrect'] ?? false;

            Color borderColor = Colors.grey.shade300;
            Color bgColor = Colors.transparent;

            if (_isCorrect != null && isSelected) {
              if (isCorrectAnswer) {
                borderColor = Colors.green;
                bgColor = Colors.green.shade50;
              } else {
                borderColor = Colors.red;
                bgColor = Colors.red.shade50;
              }
            } else if (_isCorrect != null && isCorrectAnswer) {
              borderColor = Colors.green;
              bgColor = Colors.green.shade50;
            }

            return GestureDetector(
              onTap: _isCorrect == null
                  ? () {
                      setState(() {
                        _selectedAnswer = optionId;
                        _isCorrect = isCorrectAnswer;
                      });

                      if (isCorrectAnswer) {
                        Future.delayed(const Duration(milliseconds: 800), () {
                          widget.onCompleted();
                        });
                      }
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (option['imageUrl'] != null)
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(option['imageUrl']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        option['text'] ?? 'Opción',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    if (isSelected && _isCorrect != null)
                      Icon(
                        _isCorrect! ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect! ? Colors.green : Colors.red,
                        size: 28,
                      ),
                  ],
                ),
              ),
            );
          }),
          if (_isCorrect != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect!
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  border: Border.all(
                    color: _isCorrect! ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isCorrect!
                      ? (widget.feedbackCorrect ?? '¡Correcto!')
                      : (widget.feedbackIncorrect ?? 'Intenta de nuevo'),
                  style: TextStyle(
                    color: _isCorrect! ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// VIDEO STEP
// ==========================================
class _VideoStep extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;
  final VoidCallback onCompleted;

  const _VideoStep({
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.onCompleted,
  });

  @override
  State<_VideoStep> createState() => _VideoStepState();
}

class _VideoStepState extends State<_VideoStep> {
  bool _videoCompleted = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎬 Video',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Placeholder para video
                Icon(
                  Icons.play_circle_fill,
                  size: 80,
                  color: Colors.orange.shade400,
                ),
                // TODO: Implementar video player (video_player package)
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _videoCompleted = true);
              widget.onCompleted();
            },
            icon: const Icon(Icons.check),
            label: Text(
              _videoCompleted ? 'Video Completado ✓' : 'He visto el video',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _videoCompleted ? Colors.green : Colors.orange,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// AUDIO STEP
// ==========================================
class _AudioStep extends StatefulWidget {
  final String audioUrl;
  final String title;
  final String transcript;
  final VoidCallback onCompleted;

  const _AudioStep({
    required this.audioUrl,
    required this.title,
    required this.transcript,
    required this.onCompleted,
  });

  @override
  State<_AudioStep> createState() => _AudioStepState();
}

class _AudioStepState extends State<_AudioStep> {
  bool _audioPlayed = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔊 Audio',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.volume_up, size: 80, color: Colors.orange.shade600),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _audioPlayed = true);
              // TODO: Implementar audio player real
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Reproducir Audio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          if (widget.transcript.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Transcripción:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              widget.transcript,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
          const SizedBox(height: 24),
          if (_audioPlayed)
            Center(
              child: ElevatedButton(
                onPressed: () => widget.onCompleted(),
                child: const Text('Continuar'),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// IMAGE STEP
// ==========================================
class _ImageStep extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String caption;
  final VoidCallback onCompleted;

  const _ImageStep({
    required this.imageUrl,
    required this.title,
    required this.caption,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🖼️ Imagen',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            caption,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onCompleted,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TEXT STEP
// ==========================================
class _TextStep extends StatelessWidget {
  final String title;
  final String content;
  final String? imageUrl;
  final VoidCallback onCompleted;

  const _TextStep({
    required this.title,
    required this.content,
    this.imageUrl,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onCompleted,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}
