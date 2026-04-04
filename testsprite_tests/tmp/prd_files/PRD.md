# Product Requirements Document — Bara (CookLevel)

**Version:** 1.0  
**Fecha:** 2026-04-01  
**Estado:** En desarrollo activo

---

## 1. Visión del Producto

**Bara** (también conocido como *CookLevel* o *Cappy*) es la primera aplicación móvil que enseña a cocinar como si fuera un videojuego. Con una mecánica inspirada en Duolingo, el usuario aprende recetas, técnicas culinarias y cultura gastronómica a través de lecciones cortas, gamificadas y progresivas, vinculadas a países y culturas del mundo.

> "Aprende a cocinar como aprendiste inglés."

---

## 2. Problema

Millones de personas quieren aprender a cocinar pero:

- Los cursos en video son largos y requieren tiempo continuo
- Los libros de cocina no tienen interactividad ni retroalimentación
- Las apps de recetas no enseñan, solo listan ingredientes
- No existe una curva de aprendizaje progresiva que lleve al usuario de cero a chef competente

El resultado es que la mayoría abandona antes de desarrollar habilidades reales.

---

## 3. Propuesta de Valor

| Para el usuario | Bara ofrece |
|---|---|
| Quiere aprender a cocinar pero no tiene tiempo | Lecciones de 3–5 min por día |
| Se frustra sin retroalimentación inmediata | Quiz interactivo con corrección instantánea |
| Pierde motivación rápido | Sistema de vidas, rachas, XP y desbloqueos |
| No sabe por dónde empezar | Rutas de aprendizaje por país o por objetivo personal |
| Quiere contexto cultural de las comidas | Módulos de cultura gastronómica por región |

---

## 4. Objetivos del Producto

### 4.1 Objetivos de Negocio
- Lograr retención de Día 7 superior al 20% versus apps de cocina tradicionales
- Alcanzar una racha promedio de 5+ días entre usuarios activos
- Construir base técnica lista para monetización freemium (contenido premium + vidas)

### 4.2 Objetivos de Usuario
- El usuario puede completar su primera receta desde cero en la sesión 1
- El usuario desarrolla hábito de cocinar en menos de 2 semanas de uso diario
- El usuario entiende el contexto cultural de los platos que aprende

---

## 5. Usuarios Objetivo

### Perfil Primario — "El curioso sin habilidades"
- Edad: 18–35 años
- Cocina poco o nada; come fuera o comida preparada
- Usa apps de entretenimiento y juegos móviles (Duolingo, TikTok, Candy Crush)
- Motivación: independencia, salud, impresionar a otros
- Frustración: no sabe por dónde empezar, abandona los cursos largos

### Perfil Secundario — "El cocinero casual"
- Cocina recetas básicas, quiere expandir su repertorio
- Busca aprender técnicas específicas (cuchillo, salsas, masas)
- Motivación: creatividad, bienestar, ahorro de dinero

### Perfil Terciario — "El entusiasta cultural"
- Interés en gastronomía como expresión cultural
- Quiere entender el origen y significado de los platos del mundo
- Disfruta el componente educativo y de viajes

---

## 6. Funcionalidades del Producto

### 6.1 Autenticación y Onboarding

| ID | Funcionalidad | Prioridad |
|---|---|---|
| F-01 | Registro con email/contraseña (validación zxcvbn) | P0 |
| F-02 | Login con JWT y almacenamiento seguro | P0 |
| F-03 | Onboarding de 4 pasos: intro → modo → selección → inicio | P0 |
| F-04 | Selección de modo: Aprender por País vs Aprender por Objetivo | P0 |
| F-05 | Avatar e identidad de usuario (nombre, ícono) | P1 |

### 6.2 Experiencia de Aprendizaje

| ID | Funcionalidad | Prioridad |
|---|---|---|
| F-06 | Rutas de aprendizaje por país (recetas + técnicas + cultura) | P0 |
| F-07 | Rutas de aprendizaje por objetivo (escuela de cocina, dieta, fitness, vegano) | P0 |
| F-08 | Mapa de progresión visual con nodos bloqueados/desbloqueados | P0 |
| F-09 | Lección gamificada estilo Duolingo (quiz + retroalimentación instantánea) | P0 |
| F-10 | Tipos de nodo: receta, técnica, habilidad, quiz, explicación, tips, cultural, desafío | P0 |
| F-11 | Pasos multimedia: texto, imagen, video, audio, animación interactiva | P1 |
| F-12 | Sistema de desbloqueo progresivo (nodo A habilita nodo B) | P0 |
| F-13 | Hub de país: recetas, cultura y escuela de cocina | P1 |

### 6.3 Gamificación

| ID | Funcionalidad | Prioridad |
|---|---|---|
| F-14 | Sistema de vidas (3 vidas, recarga en 24h) | P0 |
| F-15 | Pantalla de "sin vidas" bloqueante con timer de recarga | P0 |
| F-16 | XP por lección completada (valor configurable por nodo, default 50 XP) | P0 |
| F-17 | Niveles de usuario basados en XP acumulado | P0 |
| F-18 | Rachas diarias (streak) con contador visible | P0 |
| F-19 | Retroalimentación visual/sonora: confetti, animaciones, sonidos | P1 |
| F-20 | Tabla de posiciones global (leaderboard) | P1 |
| F-21 | Técnicas desbloqueadas y países completados como logros | P1 |

### 6.4 Perfil y Progreso

| ID | Funcionalidad | Prioridad |
|---|---|---|
| F-22 | Pantalla de perfil con stats (XP, nivel, racha, lecciones completadas) | P0 |
| F-23 | Seguimiento de progreso por ruta de aprendizaje | P0 |
| F-24 | Despensa/inventario (ingredientes recolectados durante lecciones) | P2 |
| F-25 | Cambio de contraseña y gestión de cuenta | P1 |

### 6.5 Panel de Administración

| ID | Funcionalidad | Prioridad |
|---|---|---|
| F-26 | Editor de nodos de aprendizaje (árbol visual, tipo WYSIWYG) | P0 |
| F-27 | Gestión de países (crear, editar, ordenar, activar) | P0 |
| F-28 | Biblioteca de nodos con importación/vinculación | P1 |
| F-29 | Carga de medios a Cloudinary (imagen y video) | P0 |
| F-30 | Gestión de usuarios y roles (user/admin) | P1 |

---

## 7. Arquitectura del Sistema

### 7.1 Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Frontend | Flutter (Dart 3.8.1), Provider state management |
| Backend | Node.js + Express v5, MongoDB + Mongoose |
| Auth | JWT Bearer tokens, bcrypt + zxcvbn |
| Media | Cloudinary (imágenes y videos) |
| Seguridad | express-rate-limit, roles user/admin |
| Testing | Jest + Supertest + mongodb-memory-server |
| Docs | Swagger UI (auto-generado) |

### 7.2 Entidades del Dominio

```
User
  ├── UserProgress (por ruta)
  └── Pantry (ingredientes)

LearningPath (country_recipe | country_culture | goal)
  └── LearningNode (receta | técnica | quiz | cultural | ...)
        ├── Steps (texto | imagen | video | quiz | timer | animación)
        └── UnlocksNodes → otros LearningNodes

Country
  ├── LearningPaths
  └── Recipes / Skills / Culture

Recipe / Skill / Culture
  └── Steps
```

### 7.3 Módulos de API (v2 `/api`)

| Módulo | Descripción |
|---|---|
| `/auth` | Registro, login, perfil, cambio de contraseña |
| `/learning-path` | Rutas de aprendizaje (CRUD + árbol de nodos) |
| `/learning-node` | Nodos individuales, completación, desbloqueo |
| `/progress` | Progreso por ruta, completación de lecciones |
| `/country` `/countries` | Hubs de países, progreso por país |
| `/recipe` | Recetas con pasos e ingredientes |
| `/skill` | Habilidades culinarias |
| `/culture` | Contenido cultural por país |
| `/lives` | Estado de vidas y recarga |
| `/leaderboard` | Ranking global |
| `/pantry` | Despensa/inventario del usuario |
| `/upload` | Carga de medios a Cloudinary |
| `/admin` | Gestión de contenido y usuarios (admin) |

---

## 8. Flujos de Usuario

### 8.1 Flujo de Onboarding
```
Bienvenida
  → Registro / Login
  → Introducción (mascota Cappy)
  → Selección de modo: [Por País] o [Por Objetivo]
  → Selección específica (país de interés o meta culinaria)
  → Experiencia Principal
```

### 8.2 Flujo de Aprendizaje por País (primario)
```
Pestaña Países
  → Mapa de países (bloqueados/desbloqueados por nivel)
  → Hub del País (secciones: Recetas, Cultura, Escuela de Cocina)
  → Mapa de progresión (árbol de nodos)
  → Seleccionar nodo disponible
  → Lección gamificada (pasos + quiz)
  → Retroalimentación (correcto/incorrecto + animación)
  → Recompensa: XP + racha + desbloqueo del siguiente nodo
```

### 8.3 Flujo de Aprendizaje por Objetivo
```
Pestaña Objetivos
  → Seleccionar objetivo (Escuela de cocina | Bajar peso | Ganar músculo | Vegano)
  → Ruta de progresión específica al objetivo
  → Nodos de recetas/técnicas alineados al objetivo
  → Misma experiencia de lección gamificada
```

### 8.4 Flujo de Vidas Agotadas
```
Completar lección incorrectamente → Pierde 1 vida
  → 0 vidas → Pantalla bloqueante con countdown de recarga
  → (futuro) Opción de comprar recarga inmediata
  → Recarga automática a las 24h → Puede continuar
```

---

## 9. Modelo de Gamificación

### Sistema de Vidas
- 3 vidas máximo por usuario
- Se pierde 1 vida al completar incorrectamente o usar una lección
- Recarga automática: 1 vida cada 8h (o recarga completa a las 24h)
- Pantalla bloqueante cuando vidas = 0

### Sistema de XP y Niveles
- Cada nodo tiene `xpReward` configurable (default: 50 XP, mínimo: 10 XP)
- XP se acumula globalmente y por ruta
- Nivel de usuario = función de `totalXP` acumulado
- El nivel desbloquea países con `unlockLevel` requerido

### Rachas (Streaks)
- Contador de días consecutivos de aprendizaje
- Visible en el perfil y cabecera principal
- Reinicio si no se completa ninguna lección en el día
- (futuro) Escudo de racha para proteger un día perdido

### Desbloqueo Progresivo
- Nodos bloqueados por defecto (`isLockedByDefault: true`)
- Completar nodo A puede desbloquear nodos B, C... (`unlocksNodes`)
- Países requieren nivel mínimo o grupos completados para desbloquear
- Progresión lineal/árbol según diseño de contenido

---

## 10. Sistema de Contenido

### Tipos de Nodo

| Tipo | Descripción |
|---|---|
| `recipe` | Receta completa con pasos, ingredientes, utensilios y nutrición |
| `technique` | Técnica específica (cuchillo, calor, sazonado) |
| `skill` | Habilidad culinaria amplia que desbloquea otras habilidades/recetas |
| `quiz` | Preguntas de conocimiento con retroalimentación |
| `explanation` | Contenido educativo en texto/video |
| `tips` | Consejos profesionales y trucos |
| `cultural` | Contexto cultural e histórico de la gastronomía |
| `challenge` | Receta difícil o cronometrada |
| `defense` | Aplicación avanzada de técnicas |

### Tipos de Paso (dentro de un nodo)

| Tipo | Descripción |
|---|---|
| `text` | Instrucción o explicación textual |
| `image` | Imagen de referencia |
| `video` | Video demostrativo |
| `quiz` | Pregunta de opción múltiple con retroalimentación |
| `checklist` | Lista de verificación de ingredientes/utensilios |
| `timer` | Paso cronometrado (ej. "cocinar 5 minutos") |
| `animation` | Tarjeta animada interactiva |

### Niveles de Dificultad
- Recetas / Nodos: 1–3 estrellas
- Habilidades: principiante, intermedio, avanzado
- Cultura: fácil, medio, difícil

---

## 11. Diseño Visual

### Paleta de Colores (Sistema Cappy Green)

| Rol | Color | Uso |
|---|---|---|
| **Primario (Cappy Green)** | `#22C55E` | Botones de acción, "Continuar", checks de éxito |
| **Secundario (Gamification Orange)** | `#FF6B35` | Recompensas, timer, racha/fuego, logros |
| **Crítico (Red)** | `#EF4444` | Indicador de vidas, estados críticos |
| **Éxito oscuro** | `#16A34A` | Confirmación, gradientes de éxito |
| **Fondo** | `#F8FAFC` | Fondos claros neutros |
| **Superficie** | `#FFFFFF` | Tarjetas, contenedores |
| **Borde** | `#E2E8F0` | Divisores, separación sutil |

### Principios de UX
- **Bajo fricción:** lecciones de 3–5 minutos, sin formularios largos
- **Retroalimentación inmediata:** correcto/incorrecto en menos de 500ms
- **Multi-sensorial:** visual (animaciones) + audio (sonidos de juego) + háptico (vibración)
- **Progresión visible:** el mapa de nodos muestra siempre el estado de avance
- **Consistencia:** sistema de colores y tokens de animación unificados

---

## 12. Monetización (Roadmap)

La arquitectura soporta un modelo **freemium**. Las siguientes funcionalidades están preparadas en el modelo de datos pero aún no activadas:

| Feature | Descripción | Estado |
|---|---|---|
| Contenido premium | `isPremium: true` en recetas, habilidades, cultura y rutas | Ready in model |
| Recarga de vidas | Pago para recuperar vidas inmediatamente | Framework ready |
| Cosméticos | Avatares e íconos exclusivos | Partial |
| Ruta premium | Rutas de aprendizaje avanzadas (chef profesional, etc.) | Planned |

---

## 13. Métricas de Éxito

| Métrica | Target | Notas |
|---|---|---|
| Tiempo por pregunta | 3–4 segundos | Ritmo tipo Duolingo |
| Duración de sesión | 5–15 minutos | Sesión de hábito |
| Retención Día 1 | > 60% | Onboarding efectivo |
| Retención Día 7 | > 20% | Gamificación activa |
| Retención Día 30 | > 10% | Profundidad de contenido |
| Racha promedio | 5+ días | Formación de hábito |
| Tasa de completación de lección | > 70% | Baja fricción |
| NPS | > 40 | Calidad percibida |

---

## 14. Estado Actual y Roadmap

### Completado
- [x] Sistema de autenticación completo (JWT + roles)
- [x] Onboarding de 4 pasos con selección de modo
- [x] Pantalla de lección gamificada estilo Duolingo
- [x] Sistema de vidas (3 vidas, recarga por timer)
- [x] XP, niveles y rachas
- [x] Rutas de aprendizaje por país y por objetivo
- [x] Mapa de progresión con nodos bloqueados/desbloqueados
- [x] Hub de país con secciones
- [x] Panel de administración v2 con editor de árbol de nodos
- [x] Unificación del sistema de colores (Cappy Green)
- [x] Arquitectura de animaciones y motion tokens
- [x] Tarjetas de animación interactivas

### En Progreso
- [ ] Soporte de quiz multi-selección (múltiples respuestas correctas)
- [ ] Carga de imágenes en tarjetas de animación
- [ ] Mejoras de audio y retroalimentación multisensorial

### Planeado (Next)
- [ ] Notificaciones push para rachas y recordatorios diarios
- [ ] Escudo de racha (protege un día perdido)
- [ ] Activación de contenido premium y paywall de vidas
- [ ] Sistema de amigos y retos sociales
- [ ] Modo offline para lecciones descargadas
- [ ] Expansión de contenido: 10+ países, 200+ recetas

---

## 15. Restricciones y Suposiciones

### Restricciones Técnicas
- La app requiere conexión a internet (sin modo offline en v1)
- Los medios dependen de Cloudinary (latencia de CDN)
- Flutter limita distribución nativa a iOS y Android

### Suposiciones de Negocio
- El usuario tiene motivación intrínseca suficiente para usar la app diariamente
- El contenido culinario es suficientemente universal para mercados hispanohablantes
- El modelo de vidas no genera abandono sino urgencia y retorno

### Dependencias
- Cloudinary: almacenamiento y entrega de imágenes y videos
- MongoDB Atlas: base de datos en la nube
- App Store y Google Play: distribución y pagos in-app (futuro)

---

*Documento generado el 2026-04-01. Para contribuciones o cambios, actualizar también la versión y la fecha.*
