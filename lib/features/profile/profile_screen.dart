import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Quieres cerrar tu sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Cerrar Sesión"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final progress = context.watch<ProgressProvider>().progress;

    final level = (progress.xp ~/ 100) + 1;
    final xpInLevel = progress.xp % 100;
    final xpForNextLevel = 100;
    final progressPercent = xpInLevel / xpForNextLevel;

    return Scaffold(
      appBar: AppBar(
        title: const Text("👨‍🍳 Mi Perfil"),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: "Cerrar Sesión",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== HEADER CON AVATAR =====
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade600, Colors.orange.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 56,
                            color: Colors.orange.shade600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      authProvider.token != null
                          ? "Chef en Progreso"
                          : "Usuario",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Nivel $level",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ===== BARRA DE PROGRESO XP =====
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Experiencia",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$xpInLevel / $xpForNextLevel XP",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(Colors.orange.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ===== ESTADÍSTICAS =====
            const Text(
              "📊 Estadísticas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle,
                    color: Colors.green,
                    value: progress.completedLessons.length.toString(),
                    label: "Completadas",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.lock_open,
                    color: Colors.blue,
                    value: progress.unlockedLessons.length.toString(),
                    label: "Desbloqueadas",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    color: Colors.red,
                    value: progress.streak.toString(),
                    label: "Racha",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.star,
                    color: Colors.amber,
                    value: progress.xp.toString(),
                    label: "XP Total",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.favorite,
                    color: Colors.pink,
                    value: "0",
                    label: "Favoritas",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.trending_up,
                    color: Colors.purple,
                    value: (level - 1).toString(),
                    label: "Niveles",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ===== ACHIEVEMENTS =====
            const Text(
              "🏆 Logros",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AchievementBadge(
                  emoji: "🌟",
                  title: "Primer Paso",
                  unlocked: progress.completedLessons.isNotEmpty,
                ),
                _AchievementBadge(
                  emoji: "🔥",
                  title: "Racha",
                  unlocked: progress.streak >= 3,
                ),
                _AchievementBadge(
                  emoji: "🎓",
                  title: "Aprendiz",
                  unlocked: progress.completedLessons.length >= 5,
                ),
                _AchievementBadge(
                  emoji: "👨‍🍳",
                  title: "Chef",
                  unlocked: progress.completedLessons.length >= 20,
                ),
                _AchievementBadge(
                  emoji: "💎",
                  title: "Experto",
                  unlocked: level >= 10,
                ),
                _AchievementBadge(
                  emoji: "🌍",
                  title: "Viajero",
                  unlocked:
                      false, // TODO: desbloquear cuando visite todos los países
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ===== ACCIONES =====
            const Text(
              "⚙️ Acciones",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.explore,
              label: "Explorar Recetas",
              onTap: () => Navigator.pushNamed(context, "/main"),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.kitchen,
              label: "Mi Despensa",
              onTap: () => Navigator.pushNamed(context, "/pantry"),
            ),
            if (authProvider.isAdmin) ...[
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.admin_panel_settings,
                label: "Panel Administrativo",
                color: Colors.deepPurple,
                onTap: () => Navigator.pushNamed(context, "/admin"),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text("Cerrar Sesión"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ===== STAT CARD COMPONENT =====
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== ACHIEVEMENT BADGE COMPONENT =====
class _AchievementBadge extends StatelessWidget {
  final String emoji;
  final String title;
  final bool unlocked;

  const _AchievementBadge({
    required this.emoji,
    required this.title,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.4,
      child: Tooltip(
        message: unlocked ? "¡Desbloqueado!" : "Por desbloquear",
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: unlocked ? Colors.amber.shade50 : Colors.grey.shade200,
            border: Border.all(
              color: unlocked ? Colors.amber : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== ACTION BUTTON COMPONENT =====
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            border: Border.all(color: color.withAlpha(128)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
