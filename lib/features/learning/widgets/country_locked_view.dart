import 'dart:convert';

import 'package:flutter/material.dart';
import 'learning_state_actions.dart';
import 'learning_state_card.dart';
import 'learning_state_heading.dart';

class CountryLockedView extends StatelessWidget {
  final Object error;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const CountryLockedView({
    super.key,
    required this.error,
    required this.onBack,
    required this.onRetry,
  });

  static _CountryLockedViewModel parseError(Object error) {
    final raw = error.toString();
    final normalized = raw.startsWith('Exception: ')
        ? raw.substring('Exception: '.length)
        : raw;

    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(normalized);
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      }
    } catch (_) {
      payload = null;
    }

    final codeRaw = payload == null ? null : payload['code'];
    final code = codeRaw?.toString();

    final unlockRaw = payload == null ? null : payload['unlock'];
    final Map<String, dynamic>? unlock = unlockRaw is Map<String, dynamic>
        ? Map<String, dynamic>.from(unlockRaw)
        : null;

    if (code == 'PREMIUM_REQUIRED') {
      return const _CountryLockedViewModel(
        title: 'País premium',
        description: 'Este país está disponible solo para usuarios premium.',
        icon: Icons.workspace_premium_outlined,
      );
    }

    if (code == 'LEVEL_REQUIRED') {
      final unlockLevelRaw = unlock == null ? null : unlock['unlockLevel'];
      final unlockLevel = (unlockLevelRaw is num) ? unlockLevelRaw.toInt() : 1;
      return _CountryLockedViewModel(
        title: 'Nivel insuficiente',
        description:
            'Necesitas llegar al nivel $unlockLevel para entrar a este país.',
        icon: Icons.lock_clock_outlined,
      );
    }

    if (code == 'GROUPS_REQUIRED') {
      final missingRaw = unlock == null ? null : unlock['missingGroupIds'];
      final missing = (missingRaw as List?)?.length ?? 0;
      return _CountryLockedViewModel(
        title: 'Progreso pendiente',
        description: missing > 0
            ? 'Completa $missing grupo(s) de contenido para desbloquear este país.'
            : 'Completa los grupos requeridos para desbloquear este país.',
        icon: Icons.account_tree_outlined,
      );
    }

    return _CountryLockedViewModel(
      title: 'Error al cargar',
      description:
          (payload == null ? null : payload['message'])?.toString() ??
          'No se pudo cargar el país seleccionado.',
      icon: Icons.error_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    final vm = parseError(error);

    return LearningStateCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(vm.icon, size: 48, color: primaryBlue),
          const SizedBox(height: 14),
          LearningStateHeading(title: vm.title, description: vm.description),
          const SizedBox(height: 18),
          LearningStateActions(onBack: onBack, onRetry: onRetry),
        ],
      ),
    );
  }
}

class _CountryLockedViewModel {
  final String title;
  final String description;
  final IconData icon;

  const _CountryLockedViewModel({
    required this.title,
    required this.description,
    required this.icon,
  });
}
