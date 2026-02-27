import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import '../../../core/models/learning_node.dart';

class LessonFlowScreen extends StatefulWidget {
  final LearningNode node;
  final VoidCallback? onComplete;

  const LessonFlowScreen({super.key, required this.node, this.onComplete});

  @override
  State<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends State<LessonFlowScreen> {
  late int _currentStepIndex;
  bool _showChecklist = true;
  List<bool> _checklistItems = [];
  bool _isCompleting = false;
  Map<String, dynamic>? _completionResult;

  @override
  void initState() {
    super.initState();
    _currentStepIndex = 0;

    // Initialize checklist for recipes
    if (widget.node.type == 'recipe' &&
        widget.node.ingredients != null &&
        widget.node.ingredients!.isNotEmpty) {
      _checklistItems = List.filled(widget.node.ingredients!.length, false);
    }
  }

  Future<void> _completeNode() async {
    if (_isCompleting) return;

    setState(() => _isCompleting = true);

    try {
      final result = await ApiService.completeNode(widget.node.id);
      setState(() {
        _completionResult = result;
        _isCompleting = false;
      });

      // Show completion dialog
      if (mounted) {
        _showCompletionDialog(result);
      }
    } catch (e) {
      setState(() => _isCompleting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCompletionDialog(Map<String, dynamic> result) {
    final progress = result['progress'] as Map<String, dynamic>?;
    final streak =
        (progress?['streak'] as num?)?.toInt() ??
        (result['streak'] as num?)?.toInt() ??
        0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Felicidades!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Ganaste ${result['xpEarned']} XP',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('XP Total: ${result['totalXp']}'),
            const SizedBox(height: 8),
            Text('Nivel: ${result['level']}'),
            const SizedBox(height: 8),
            Text('Racha: $streak día${streak == 1 ? '' : 's'}'),
            if (result['unlockedNodes'] != null &&
                (result['unlockedNodes'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  children: [
                    const Text(
                      '¡Nodos desbloqueados!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...(result['unlockedNodes'] as List).map(
                      (node) => Text('• ${node['title']}'),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Only pop the dialog
              Navigator.pop(context);
              // Then pop the lesson screen
              Navigator.pop(context, true);
              widget.onComplete?.call();
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show loading screen separately - show it in dialog
    final step = widget.node.steps[_currentStepIndex];

    return WillPopScope(
      onWillPop: () async {
        if (_currentStepIndex > 0) {
          setState(() => _currentStepIndex--);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.node.title),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          actions: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '${_currentStepIndex + 1}/${widget.node.steps.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_currentStepIndex + 1) / widget.node.steps.length,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Checklist for recipes (show once at start)
                if (_showChecklist &&
                    widget.node.type == 'recipe' &&
                    widget.node.ingredients != null &&
                    widget.node.ingredients!.isNotEmpty)
                  _buildChecklistSection(),

                // Step content
                _buildStepContent(step),

                const SizedBox(height: 32),

                // Navigation buttons
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ingredientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(
                _showChecklist ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () {
                setState(() => _showChecklist = !_showChecklist);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(widget.node.ingredients!.length, (index) {
          final ingredient = widget.node.ingredients![index];
          return CheckboxListTile(
            value: _checklistItems[index],
            onChanged: (value) {
              setState(() {
                _checklistItems[index] = value ?? false;
              });
            },
            title: Text(
              '${ingredient.quantity} ${ingredient.unit} de ${ingredient.name}',
            ),
            subtitle: ingredient.optional
                ? const Text('Opcional', style: TextStyle(fontSize: 12))
                : null,
            contentPadding: EdgeInsets.zero,
          );
        }),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            'Prep Time: ${widget.node.prepTime ?? 'N/A'} min | Cook Time: ${widget.node.cookTime ?? 'N/A'} min',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStepContent(NodeStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step title
        Text(
          step.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        // Step media (image/video)
        if (step.image != null || step.video != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[200],
              child: Center(
                child: step.image != null
                    ? Image.network(
                        step.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey[400],
                          );
                        },
                      )
                    : Icon(
                        Icons.play_circle,
                        size: 64,
                        color: Colors.grey[400],
                      ),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Instruction text
        Text(
          step.instruction,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),

        // Tips
        if (step.tips != null && step.tips!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Consejos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...step.tips!.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $tip', style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Feedback if available
        if (step.feedback != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.feedback!,
                    style: TextStyle(color: Colors.green[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStepIndex == widget.node.steps.length - 1;

    return Row(
      children: [
        if (_currentStepIndex > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() => _currentStepIndex--);
              },
              child: const Text('Anterior'),
            ),
          ),
        if (_currentStepIndex > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isCompleting
                ? null
                : isLastStep
                ? _completeNode
                : () {
                    setState(() => _currentStepIndex++);
                  },
            child: _isCompleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isLastStep ? 'Completar' : 'Siguiente'),
          ),
        ),
      ],
    );
  }
}
