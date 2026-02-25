import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class StepTimerWidget extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onTimerEnd;

  const StepTimerWidget({
    required this.durationSeconds,
    required this.onTimerEnd,
    Key? key,
  }) : super(key: key);

  @override
  State<StepTimerWidget> createState() => _StepTimerWidgetState();
}

class _StepTimerWidgetState extends State<StepTimerWidget> {
  int secondsLeft = 0;
  bool running = false;
  bool finished = false;
  AudioPlayer? player;

  @override
  void dispose() {
    player?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    secondsLeft = widget.durationSeconds;
  }

  void startTimer() {
    setState(() {
      secondsLeft = widget.durationSeconds;
      running = true;
      finished = false;
    });
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (!running || secondsLeft <= 0) return false;
      setState(() => secondsLeft--);
      if (secondsLeft == 0) {
        running = false;
        finished = true;
        playAlarm();
        widget.onTimerEnd();
      }
      return running;
    });
  }

  void pauseTimer() {
    setState(() => running = false);
  }

  void resumeTimer() {
    if (secondsLeft > 0) setState(() => running = true);
  }

  void cancelTimer() {
    setState(() {
      running = false;
      secondsLeft = widget.durationSeconds;
      finished = false;
    });
  }

  Future<void> playAlarm() async {
    try {
      player = AudioPlayer();
      await player!.play(AssetSource('sounds/alarma.mp3'));
    } catch (e) {
      // Manejar error de audio
    }
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
            color: Color(0xFFFF6B35),
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
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
                  foregroundColor: const Color(0xFFFF6B35),
                  side: const BorderSide(color: Color(0xFFFF6B35)),
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
                  foregroundColor: const Color(0xFFFF6B35),
                  side: const BorderSide(color: Color(0xFFFF6B35)),
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
            style: TextStyle(color: Color(0xFF27AE60)),
          ),
      ],
    );
  }
}
