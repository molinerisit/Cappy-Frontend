import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/audio_feedback_service.dart';
import '../core/lives_service.dart';
import '../widgets/lives_widget.dart';
import 'no_lives_screen.dart';

class LearningNodeViewerScreen extends StatefulWidget {
  final String nodeId;
  final String nodeTitle;

  const LearningNodeViewerScreen({
    super.key,
    required this.nodeId,
    required this.nodeTitle,
  });

  @override
  State<LearningNodeViewerScreen> createState() =>
      _LearningNodeViewerScreenState();
}

class _LearningNodeViewerScreenState extends State<LearningNodeViewerScreen> {
  late Future<Map<String, dynamic>> _futureNode;
  int _currentStepIndex = 0;
  int _currentCardIndex = 0;

  // Lives system
  late LivesService _livesService;
  int _currentLives = 3;
  int _maxLives = 3;
  DateTime? _nextRefillAt;
  bool _isNoLivesScreenOpen = false;

  @override
  void initState() {
    super.initState();
    _futureNode = _loadNode();
    _initializeLives();
  }

  void _initializeLives() {
    // Initialize lives service with baseUrl from ApiService
    _livesService = LivesService(baseUrl: ApiService.baseUrl);
    _loadLives();
  }

  Future<void> _loadLives() async {
    try {
      final token = ApiService.getToken();
      if (token == null) {
        debugPrint('DEBUG: No token available');
        // Set default values and mark as loaded
        if (mounted) {
          setState(() {
            _currentLives = 3;
            _maxLives = 3;
            _nextRefillAt = null;
          });
        }
        return;
      }

      debugPrint('DEBUG: Token available, fetching lives status');
      final status = await _livesService.getLivesStatus(token);
      debugPrint('DEBUG: Lives status response: $status');

      if (mounted) {
        setState(() {
          _currentLives = status['lives'] ?? 3;
          _maxLives = 3;
          _nextRefillAt = status['nextRefillAt'] != null
              ? DateTime.parse(status['nextRefillAt'].toString())
              : null;
        });

        // Check if user has no lives
        if (_currentLives == 0) {
          _openNoLivesScreenSafely();
        }
      }
    } catch (e) {
      debugPrint('Error loading lives: $e');
      // Set default values even on error
      if (mounted) {
        setState(() {
          _currentLives = 3;
          _maxLives = 3;
          _nextRefillAt = null;
        });
      }
    }
  }

  Future<void> _loseLive() async {
    try {
      debugPrint('DEBUG: Perdiendo vida... Vidas antes: $_currentLives');
      final token = ApiService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final result = await _livesService.loseLive(token);
      debugPrint('DEBUG: Respuesta del servidor: $result');

      if (mounted) {
        setState(() {
          _currentLives = result['lives'] ?? 0;
          _nextRefillAt = result['nextRefillAt'] != null
              ? DateTime.parse(result['nextRefillAt'])
              : null;
        });

        debugPrint('DEBUG: Vidas después de actualizar: $_currentLives');

        // If no more lives, show no lives screen
        if (_currentLives == 0) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              _openNoLivesScreenSafely();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error losing life: $e');
    }
  }

  void _openNoLivesScreenSafely() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showNoLivesScreen();
    });
  }

  void _showNoLivesScreen() {
    if (!mounted || _isNoLivesScreenOpen) {
      return;
    }

    final token = ApiService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No authentication token')),
      );
      return;
    }

    _isNoLivesScreenOpen = true;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoLivesScreen(
          token: token,
          baseUrl: ApiService.baseUrl,
          onLivesRestored: () {
            _loadLives();
          },
        ),
      ),
    ).whenComplete(() {
      _isNoLivesScreenOpen = false;
    });
  }

  Future<Map<String, dynamic>> _loadNode() async {
    return ApiService.getLearningNode(widget.nodeId);
  }

  List<Map<String, dynamic>> _getSteps(Map<String, dynamic> node) {
    final steps = node['steps'];
    if (steps is List) {
      return steps
          .map(
            (s) =>
                s is Map ? Map<String, dynamic>.from(s) : <String, dynamic>{},
          )
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _getCards(Map<String, dynamic> step) {
    final cards = step['cards'];
    if (cards is List) {
      return cards
          .map(
            (c) =>
                c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{},
          )
          .toList();
    }
    return [];
  }

  void _nextCard(List<Map<String, dynamic>> steps) {
    final currentStep = steps[_currentStepIndex];
    final cards = _getCards(currentStep);

    if (_currentCardIndex < cards.length - 1) {
      setState(() => _currentCardIndex++);
    } else if (_currentStepIndex < steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _currentCardIndex = 0;
      });
    } else {
      // Lesson completed
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Lección completada! 🎉')));
    }
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      setState(() => _currentCardIndex--);
    } else if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
        // Go to last card of previous step
        _currentCardIndex = 0; // Will be updated in build
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.orange.shade700,
        toolbarHeight: 64,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        ),
        title: Text(
          widget.nodeTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 16, bottom: 6),
            child: LivesWidget(
              lives: _currentLives,
              maxLives: _maxLives,
              nextRefillAt: _nextRefillAt,
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureNode,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final node = snapshot.data!;
          final steps = _getSteps(node);

          if (steps.isEmpty) {
            return const Center(
              child: Text('Esta lección no tiene contenido aún.'),
            );
          }

          final currentStep = steps[_currentStepIndex];
          final cards = _getCards(currentStep);

          if (cards.isEmpty) {
            return const Center(child: Text('Este paso no tiene tarjetas.'));
          }

          final currentCard = cards[_currentCardIndex];
          final totalCards = steps.fold<int>(
            0,
            (sum, step) => sum + _getCards(step).length,
          );
          final currentCardNumber =
              steps
                  .take(_currentStepIndex)
                  .fold<int>(0, (sum, step) => sum + _getCards(step).length) +
              _currentCardIndex +
              1;

          return Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: currentCardNumber / totalCards,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.green.shade600,
                ),
              ),
              // Step indicator
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pregunta $currentCardNumber/$totalCards',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'Paso ${_currentStepIndex + 1}/${steps.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Card content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step title
                      Text(
                        currentStep['title'] ?? 'Paso ${_currentStepIndex + 1}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Card content
                      _buildCardContent(currentCard),
                    ],
                  ),
                ),
              ),
              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_currentStepIndex > 0 || _currentCardIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousCard,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.orange.shade700),
                          ),
                          child: Text(
                            'Anterior',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStepIndex > 0 || _currentCardIndex > 0)
                      const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _nextCard(steps),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green.shade600,
                        ),
                        child: Text(
                          (_currentCardIndex == cards.length - 1 &&
                                  _currentStepIndex == steps.length - 1)
                              ? '→ Completar Lección'
                              : 'Continuar',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> card) {
    final type = card['type'] ?? '';
    final data = card['data'] ?? {};

    switch (type) {
      case 'text':
        return _buildTextCard(data);
      case 'image':
        return _buildImageCard(data);
      case 'quiz':
        return _buildQuizCard(data);
      case 'timer':
        return _buildTimerCard(data);
      case 'video':
        return _buildVideoCard(data);
      case 'list':
        return _buildListCard(data);
      default:
        return Text('Tipo de tarjeta no soportado: $type');
    }
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

  Widget _buildDisplayImage({
    required String url,
    required double height,
    Map<String, dynamic>? display,
    BorderRadius? borderRadius,
  }) {
    final config = _normalizeImageDisplay(display);
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: Container(
        height: height,
        width: double.infinity,
        color: Colors.grey.shade100,
        child: Transform.scale(
          scale: config['zoom'] as double,
          child: Image.network(
            url,
            fit: _boxFitFromDisplay(config['fit'] as String),
            alignment: Alignment(
              config['offsetX'] as double,
              config['offsetY'] as double,
            ),
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: height,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextCard(Map<String, dynamic> data) {
    final title = data['title']?.toString();
    final text = data['text'] ?? '';
    final imageUrl = data['imageUrl']?.toString();
    final isBold = data['isBold'] ?? false;
    final isItalic = data['isItalic'] ?? false;
    final normalizedTitle = (title ?? '').trim().toLowerCase();
    final normalizedText = text.toString().trim().toLowerCase();
    final showText =
        normalizedText.isNotEmpty && normalizedText != normalizedTitle;
    final imageDisplay = _normalizeImageDisplay(data['imageDisplay']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título si existe
          if (title != null && title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Texto con formato
          if (showText)
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          // Imagen si existe
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            if (showText || (title != null && title.isNotEmpty))
              const SizedBox(height: 16),
            _buildDisplayImage(
              url: imageUrl,
              height: 200,
              display: imageDisplay,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageCard(Map<String, dynamic> data) {
    final imageUrl = (data['url'] ?? data['imageUrl'] ?? '').toString();
    final caption = data['caption'] ?? '';
    final imageDisplay = _normalizeImageDisplay(
      data['display'] ?? data['imageDisplay'],
    );

    return Column(
      children: [
        _buildDisplayImage(
          url: imageUrl,
          height: 220,
          display: imageDisplay,
          borderRadius: BorderRadius.circular(12),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            caption,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> data) {
    final question = data['question'] ?? '';
    final optionItems = data['optionItems'] is List
        ? (data['optionItems'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    final legacyOptions = data['options'] is List
        ? List<dynamic>.from(data['options'] as List)
        : <dynamic>[];
    final quizOptions = optionItems.isNotEmpty
        ? optionItems
        : legacyOptions
              .map((option) => <String, dynamic>{'text': option.toString()})
              .toList();
    final correctIndex = data['correctIndex'] ?? 0;
    final explanation = data['explanation']?.toString();
    final quizImageUrl = data['quizImageUrl']?.toString();
    final quizImageDisplay = _normalizeImageDisplay(data['quizImageDisplay']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen si existe
        if (quizImageUrl != null && quizImageUrl.isNotEmpty) ...[
          _buildDisplayImage(
            url: quizImageUrl,
            height: 180,
            display: quizImageDisplay,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.help_outline, color: Colors.blue, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...quizOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final optionData = entry.value;
          final optionText = (optionData['text'] ?? '').toString();
          final optionImageUrl =
              (optionData['imageUrl'] ?? optionData['image'] ?? '').toString();
          final optionImageDisplay = _normalizeImageDisplay(
            optionData['imageDisplay'],
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () async {
                if (index == correctIndex) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        explanation != null && explanation.isNotEmpty
                            ? '✓ $explanation'
                            : '¡Correcto! ✓',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  // Wrong answer - lose a life
                  // Reproducir sonido de error al instante
                  AudioFeedbackService().playFail();
                  
                  await _loseLive();
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Incorrecto. Vida perdida ($_currentLives/$_maxLives restantes)',
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red.shade600,
                      duration: const Duration(milliseconds: 1500),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            optionText,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    if (optionImageUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDisplayImage(
                        url: optionImageUrl,
                        height: 140,
                        display: optionImageDisplay,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimerCard(Map<String, dynamic> data) {
    final duration = data['duration'] ?? 0;
    final minutes = duration ~/ 60;
    final seconds = duration % 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer, size: 64, color: Colors.purple),
          const SizedBox(height: 16),
          Text(
            '$minutes:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Temporizador',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> data) {
    final videoUrl = data['videoUrl'] ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.play_circle_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Video: $videoUrl'),
        ],
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> data) {
    final items = data['items'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.toString(),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
