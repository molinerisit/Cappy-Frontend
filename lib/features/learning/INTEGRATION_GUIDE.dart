// ============================================================================
// GUÍA DE INTEGRACIÓN: Cómo usar la nueva pantalla de lección
// ============================================================================

/*

## 1. REEMPLAZAR IMPORTACIÓN

// ANTES:
import '../../../features/learning/screens/lesson_flow_screen.dart';

// AHORA:
import '../../../features/learning/screens/lesson_flow_screen_duolingo.dart';


## 2. USAR EN PathProgressionScreen (o donde navegues a lección)

// ANTES:
final result = await Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => LessonFlowScreen(
      lessonId: nodeId,
      lessonTitle: title,
      lessonType: nodeType,
      steps: steps,
    ),
  ),
);

// AHORA:
final learningNode = LearningNode(
  id: nodeId,
  title: title,
  type: nodeType,
  steps: steps, // Ya tienes estos pasos
  // ... otros campos
);

final result = await Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => LessonFlowScreenDuolingo(
      node: learningNode,
      onComplete: () {
        // Refresca el árbol o lo que necesites
        _refreshProgress();
      },
    ),
  ),
);


## 3. ESTRUCTURA ESPERADA DE NodeStep

```dart
class NodeStep {
  final String title;              // "¿Cuál es el ingrediente principal?"
  final String? image;             // URL de imagen (opcional)
  final String instruction;        // Instrucción / descripción
  final List<String> options;      // ["Tomate", "Papa", "Ajo"]
  final int correctAnswerIndex;    // 0, 1, o 2
  final String? feedback;          // Feedback adicional
  final List<String>? tips;        // Tips opcionales
  // ... otros campos
}
```


## 4. ESTRUCTURA ESPERADA DE LearningNode

```dart
class LearningNode {
  final String id;
  final String title;              // "Pasta Básica"
  final String type;               // 'recipe', 'skill', etc.
  final List<NodeStep> steps;      // Tus preguntas/pasos
  final int xpReward;
  // ... otros campos necesarios para ApiService.completeNode()
}
```


## 5. SI VIENES DEL MODELO ANTERIOR

Si el modelo actual es diferente, crea un adaptador:

```dart
LearningNode adaptarAlNuevoModelo(Map<String, dynamic> apiResponse) {
  return LearningNode(
    id: apiResponse['_id'],
    title: apiResponse['title'],
    type: apiResponse['type'],
    steps: (apiResponse['steps'] as List).map((step) {
      return NodeStep(
        title: step['title'],
        image: step['image'],
        instruction: step['instruction'],
        options: List<String>.from(step['options'] ?? []),
        correctAnswerIndex: step['correctAnswerIndex'] ?? 0,
        feedback: step['feedback'],
        tips: step['tips'],
      );
    }).toList(),
    xpReward: apiResponse['xpReward'] ?? 50,
  );
}
```


## 6. FLUJO COMPLETO

```
1. Usuario está en PathProgressionScreen (árbol de nodos)
   ↓
2. Usuario tapa un nodo disponible
   ↓
3. Se abre LessonFlowScreenDuolingo
   ↓
4. Usuario ve pregunta + opciones grandes
   ↓
5. Usuario tapa una opción
   ↓
6. Animación inmediata (0-400ms)
   ↓
7. Feedback bar aparece desde abajo
   ↓
8. Usuario tapa "Siguiente"
   ↓
9. Transición a siguiente step (o CompletionDialog si es último)
   ↓
10. Usuario tapa "Continuar" en completion
    ↓
11. Vuelve a PathProgressionScreen (árbol refrescado)
```


## 7. OPCIONES DE CUSTOMIZACIÓN

### Cambiar colores:
En option_card.dart, feedback_bar.dart:
- `const Color(0xFF27AE60)` → tu verde
- `const Color(0xFFDC3545)` → tu rojo

### Cambiar animaciones:
- En `lesson_flow_screen_duolingo.dart` línea ~33:
  ```dart
  _shakeController = AnimationController(
    duration: const Duration(milliseconds: 400), // ← aquí
    vsync: this,
  );
  ```

### Cambiar textos y mensajes:
- `_getfeedbackMessage()` en lesson_flow_screen_duolingo.dart

### Agregar sonidos:
```dart
// Después de seleccionar correctamente:
if (_isAnswerCorrect!) {
  AudioPlayer().play('assets/sounds/correct.mp3');
}
```


## 8. TESTING

```dart
testWidgets('LessonFlowScreenDuolingo muestra pregunta', (tester) async {
  final node = LearningNode(
    id: '123',
    title: 'Test Lesson',
    type: 'recipe',
    steps: [
      NodeStep(
        title: '¿Cuál es correcto?',
        options: ['A', 'B', 'C'],
        correctAnswerIndex: 1,
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp(
    home: LessonFlowScreenDuolingo(node: node),
  ));

  expect(find.text('¿Cuál es correcto?'), findsOneWidget);
  expect(find.byType(OptionCard), findsWidgets);
});
```


## 9. TROUBLESHOOTING

**P: No veo el feedback bar**
R: Asegúrate de que `_state == LessonState.showingFeedback`

**P: Las opciones no se deshabilitan después de seleccionar**
R: Revisa `isEnabled: _state == LessonState.answering ...`

**P: El shake no funciona**
R: Comprueba que `_shakeController.forward()` se llama cuando `!isCorrect`

**P: La lección se ve cortada en pantalla pequeña**
R: Aumenta `SliverPadding(padding: EdgeInsets.fromLTRB(20, 24, 20, 180))`


## 10. PERFORMANCE HINTS

- ✅ Usa `const` para widgets estáticos
- ✅ Lazy load imágenes con Image.network()
- ✅ No rebuilds innecesarios (usa AnimationController bien)
- ✅ Limita a 3-5 opciones por pregunta

---

**Happy Coding! 🎮 Que disfruten la experiencia tipo Duolingo**

*/
