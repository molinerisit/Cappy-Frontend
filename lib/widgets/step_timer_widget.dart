import 'dart:async';

import 'package:flutter/material.dart';

import '../core/audio_feedback_service.dart';
import '../theme/colors.dart';
import '../theme/motion.dart';

class StepTimerWidget extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onTimerEnd;

  const StepTimerWidget({
    required this.durationSeconds,
    required this.onTimerEnd,
    super.key,
  });

  @override
  State<StepTimerWidget> createState() => _StepTimerWidgetState();
}

class _StepTimerWidgetState extends State<StepTimerWidget> {
  int secondsLeft = 0;
  bool running = false;
  bool finished = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    secondsLeft = widget.durationSeconds;
  }

  void startTimer() {
    _timer?.cancel();
    setState(() {
      secondsLeft = widget.durationSeconds;
      running = true;
      finished = false;
    });
    _startTicker();
  }

  void pauseTimer() {
    _timer?.cancel();
    setState(() => running = false);
  }

  void resumeTimer() {
    if (secondsLeft <= 0 || running) return;
    setState(() => running = true);
    _startTicker();
  }

  void cancelTimer() {
    _timer?.cancel();
    setState(() {
      running = false;
      secondsLeft = widget.durationSeconds;
      finished = false;
    });
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !running) {
        timer.cancel();
        return;
      }

      if (secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          secondsLeft = 0;
          running = false;
          finished = true;
        });
        playAlarm();
        widget.onTimerEnd();
        return;
      }

      setState(() => secondsLeft--);
    });
  }

  Future<void> playAlarm() async {
    AudioFeedbackService().playAlarm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatSeconds(secondsLeft),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 12),
        if (!running && !finished)
          ElevatedButton.icon(
            onPressed: startTimer,
            icon: const Icon(Icons.timer_outlined, size: 18),
            label: const Text('Iniciar cronómetro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              animationDuration: AppMotionDurations.quick,
            ),
          ),
        if (running)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: pauseTimer,
                icon: const Icon(Icons.pause, size: 18),
                label: const Text('Pausar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: cancelTimer,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        if (!running && secondsLeft > 0 && !finished)
          TextButton(onPressed: resumeTimer, child: const Text('Reanudar')),
        if (finished)
          const Text(
            '⏰ Tiempo finalizado',
            style: TextStyle(color: AppColors.successDark),
          ),
      ],
    );
  }
}
