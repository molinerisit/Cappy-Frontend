# 🎮 Refactorización: Pantalla de Lección tipo Duolingo

## 📋 Decisiones UX/Design

### 1. **Flujo Simplificado**
```
ANTES: Seleccionar → Botón Verificar → Botón Siguiente → Botón Completar
AHORA: Seleccionar → Feedback inmediato → CTA único
```
**Razón:** Menos pasos = menos fricción = más adictivo. El usuario tapa menos botones.

---

### 2. **Opciones de Respuesta como Cards Grandes**
- ✅ Toda la card es clickeable
- ✅ Más grande = mejor para móvil
- ✅ Mucho air visual
- ✅ Estados visuales claros sin radio buttons

**Estados:**
- `idle`: Gris claro, sin seleccionar
- `selected`: Verde claro + check
- `correct`: Verde más intenso + check grande
- `incorrect`: Rojo + X
- `disabled`: Gris desaturado (otras opciones después de responder)

---

### 3. **Feedback Inmediato sin Dialogs**
-  ✅ Feedback bar desde abajo (NO popup)
- ✅ Animación slide suave
- ✅ Mensaje positivo o constructivo (nunca castigador)
- ✅ CTA único visible

**Ejemplo de mensajes:**
- Correcto: "¡Excelente! Respuesta correcta 🎯"
- Incorrecto: "Casi lo tienes. La respuesta correcta es..."

---

### 4. **Animaciones Microinteracciones**
| Evento | Animación |
|--------|-----------|
| Tap opción | Scale 0.98 (presión visual) |
| Respuesta correcta | Fade in + scale up del check |
| Respuesta incorrecta | Shake sutil (no violento) |
| Feedback bar | Slide from bottom (500ms) |
| Transición pregunta | Fade out → Fade in |

---

### 5. **Componentes Reutilizables**

#### `LessonProgressHeader`
- Barra de progreso animada
- Contador "Paso X de Y"
- Porcentaje visual

#### `QuestionCard`
- Pregunta principal grande
- Subtítulo contextual
- Imagen opcional
- Fade animation al entrar

#### `OptionCard`
- Estados 5 visuales
- Icons dinámicos
- Scale on tap
- Todavía clickeable cuando deshabilitada

#### `FeedbackBar`
- Color según tipo de feedback
- Mensaje + CTA
- Slide animation
- Siempre visible en feedback

---

### 6. **Colores Duolingo Softer**
```
Verde correcto:    #27AE60 (suave, no neón)
Rojo incorrecto:   #DC3545 (cálido, no violento)
Gris neutral:      #D1D5DB
Fondo principal:   #F8FAFC (limpio)
Texto primario:    #1F2937 (nunca puro negro)
```

---

### 7. **Modal Completación**
- No alert() ni AlertDialog genérico
- Card custom con:
  - Emoji celebración (🎉)
  - XP ganado destacado en naranja
  - Un botón "Continuar"
- Sin info extra que abrume

---

### 8. **Estados Máquina**
```dart
enum LessonState {
  loading,           // Cargando desde servidor
  answering,         // Esperando selección
  showingFeedback,   // Mostrando feedback
  completed          // Lección completada
}
```

---

### 9. **Por Qué NO Usar Dialogs**
- ❌ Rompen el flow
- ❌ Requieren interacción extra
- ❌ Se sienten "corporativas"
- ✅ Feedback bar es más fluido y gamified

---

### 10. **Accesibilidad & Mobile-First**
- ✅ Botones/cards grandes (mín 48x48dp)
- ✅ Contraste suficiente (WCAG AA)
- ✅ Sin animations que causen mareos
- ✅ Scroll smooth, no jumpeos

---

## 🏗️ Cómo Usar

### Reemplazar pantalla antigua en PathProgressionScreen:
```dart
// ANTES:
LessonFlowScreen(node: node)

// AHORA:
LessonFlowScreenDuolingo(node: node)
```

### Para agregar más preguntas:
La pantalla lee automáticamente `widget.node.steps` y `step.options`.
Solo asegúrate de que cada `NodeStep` tenga:
- `title`: La pregunta
- `image`: URL opcional
- `options`: Lista de respuestas
- `correctAnswerIndex`: Índice de la respuesta correcta (0-based)

---

## 🎯 Resultados Esperados

### Antes
- Usuario selecciona
- Lee "¿Verificar?"
- Toca Verificar
- Se muestra resultado
- Toca Siguiente
- Se muestra pregunta siguiente
- Toca Completar

**Tiempo hasta siguiente pregunta: ~8 segundos**

### Ahora
- Usuario selecciona opción
- Feedback inmediato (~400ms)
- Toca Siguiente
- Pregunta siguiente aparece

**Tiempo hasta siguiente pregunta: ~3 segundos**

**Sensación:** Rápida, suave, adictiva. Como Duolingo real.

---

## 📱 Próximos Pasos

1. **Variants:**
   - [ ] Múltiples selecciones
   - [ ] Matching questions
   - [ ] Drag & drop
   - [ ] Typing input

2. **Gamification:**
   - [ ] Bonus points para respuestas rápidas
   - [ ] Streak visual
   - [ ] Sound effects (opcional)
   - [ ] Haptic feedback

3. **Analytics:**
   - [ ] Tiempo de respuesta
   - [ ] % aciertos
   - [ ] Abandonos en qué pregunta

---

**Versión:** 1.0 UX  
**Fecha:** 17/02/2026  
**Status:** Listo para implementar
