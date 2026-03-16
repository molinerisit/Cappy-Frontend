import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/api_service.dart';

class VideoCardPlayer extends StatefulWidget {
  final String videoUrl;
  final bool initialLooping;
  final bool initialMuted;
  final bool autoPlay;
  final bool showControls;
  final String? completionText;
  final VoidCallback? onCompleted;

  const VideoCardPlayer({
    super.key,
    required this.videoUrl,
    this.initialLooping = false,
    this.initialMuted = false,
    this.autoPlay = false,
    this.showControls = true,
    this.completionText,
    this.onCompleted,
  });

  @override
  State<VideoCardPlayer> createState() => _VideoCardPlayerState();
}

class _VideoCardPlayerState extends State<VideoCardPlayer> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _isLooping = false;
  bool _isMuted = false;
  bool _isCompleted = false;
  bool _showAchievement = false;
  bool _completionNotified = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _isLooping = widget.initialLooping;
    // Si autoreproducción activa, siempre arrancar con sonido aunque el admin
    // haya configurado muted; el alumno no tiene el control de sonido visible.
    _isMuted = widget.autoPlay ? false : widget.initialMuted;
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant VideoCardPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _isCompleted = false;
      _showAchievement = false;
      _completionNotified = false;
      _errorText = null;
      _isInitializing = true;
      _initializeController();
      return;
    }

    if (oldWidget.initialLooping != widget.initialLooping &&
        widget.initialLooping != _isLooping) {
      _setLooping(widget.initialLooping);
    }

    if (oldWidget.initialMuted != widget.initialMuted &&
        widget.initialMuted != _isMuted) {
      _setMuted(widget.initialMuted);
    }
  }

  Future<void> _initializeController() async {
    final trimmedUrl = widget.videoUrl.trim();
    if (trimmedUrl.isEmpty) {
      setState(() {
        _isInitializing = false;
        _errorText = 'No se configuró URL de video';
      });
      return;
    }

    final parsedUri = _resolveVideoUri(trimmedUrl);
    if (parsedUri == null || !parsedUri.hasScheme) {
      setState(() {
        _isInitializing = false;
        _errorText = 'URL de video inválida';
      });
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(parsedUri);
      await controller.initialize();
      await controller.setLooping(_isLooping);
      await controller.setVolume(_isMuted ? 0 : 1);
      controller.addListener(_handleVideoStateChanged);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      if (mounted && widget.autoPlay) {
        unawaited(controller.play());
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
        _errorText = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorText =
            'No se pudo cargar el video. Verifica backend y URL de media.';
      });
      debugPrint(
        'VideoCardPlayer init error for "$trimmedUrl" -> "$parsedUri": $error',
      );
    }
  }

  Uri? _resolveVideoUri(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) {
      return null;
    }

    final apiBase = Uri.tryParse(ApiService.baseUrl);
    if (apiBase == null || !apiBase.hasScheme || apiBase.host.isEmpty) {
      return parsed;
    }

    final isLocalUploadPath = parsed.path.startsWith('/uploads/');
    if (!isLocalUploadPath) {
      return parsed;
    }

    // Keep media paths stable but reuse the runtime API host to avoid
    // localhost/LAN host mismatch in Flutter web/mobile development.
    final normalized = Uri(
      scheme: apiBase.scheme,
      host: apiBase.host,
      port: apiBase.hasPort ? apiBase.port : null,
      path: parsed.path,
      query: parsed.hasQuery ? parsed.query : null,
    );

    return normalized;
  }

  void _handleVideoStateChanged() {
    final controller = _controller;
    if (controller == null) return;

    final value = controller.value;
    if (!value.isInitialized || value.duration == Duration.zero) {
      return;
    }

    final nearEnd =
        value.position >= value.duration - const Duration(milliseconds: 250);
    if (!value.isLooping &&
        nearEnd &&
        !value.isPlaying &&
        !_completionNotified) {
      _completionNotified = true;
      _triggerCompletion();
    }

    if (_completionNotified &&
        value.position < const Duration(milliseconds: 100)) {
      _completionNotified = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }

    if (_isCompleted &&
        controller.value.position >=
            controller.value.duration - const Duration(milliseconds: 250)) {
      await controller.seekTo(Duration.zero);
    }

    await controller.play();
  }

  Future<void> _setLooping(bool enabled) async {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.setLooping(enabled);
    }

    if (!mounted) return;
    setState(() {
      _isLooping = enabled;
      if (enabled) {
        _completionNotified = false;
      }
    });
  }

  Future<void> _setMuted(bool enabled) async {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.setVolume(enabled ? 0 : 1);
    }

    if (!mounted) return;
    setState(() {
      _isMuted = enabled;
    });
  }

  void _triggerCompletion() {
    if (!mounted) return;

    setState(() {
      _isCompleted = true;
      _showAchievement = true;
    });

    widget.onCompleted?.call();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        _showAchievement = false;
      });
    });
  }

  Future<void> _replayVideo() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.seekTo(Duration.zero);
    await controller.setVolume(_isMuted ? 0 : 1);
    await controller.play();
    if (!mounted) return;
    setState(() {
      _isCompleted = false;
      _completionNotified = false;
      _showAchievement = false;
    });
  }

  void _disposeController() {
    final controller = _controller;
    if (controller == null) return;
    controller.removeListener(_handleVideoStateChanged);
    controller.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: controller?.value.isInitialized == true
              ? controller!.value.aspectRatio
              : 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isInitializing)
                    const CircularProgressIndicator(color: Colors.white)
                  else if (_errorText != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _errorText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    )
                  else if (controller != null && controller.value.isInitialized)
                    VideoPlayer(controller),
                  if (_showAchievement) _buildAchievementOverlay(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (controller != null && controller.value.isInitialized)
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Colors.green.shade600,
              bufferedColor: Colors.green.shade200,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
        if (widget.showControls) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _isInitializing || _errorText != null
                    ? null
                    : _togglePlayPause,
                icon: Icon(
                  controller?.value.isPlaying == true
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                label: Text(
                  controller?.value.isPlaying == true ? 'Pausar' : 'Reproducir',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _setLooping(!_isLooping),
                icon: Icon(_isLooping ? Icons.repeat_on : Icons.repeat),
                label: Text(_isLooping ? 'Loop activo' : 'Loop inactivo'),
              ),
              OutlinedButton.icon(
                onPressed: () => _setMuted(!_isMuted),
                icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                label: Text(_isMuted ? 'Sin sonido' : 'Con sonido'),
              ),
            ],
          ),
        ],
        if (_isCompleted) ...[
          const SizedBox(height: 10),
          Center(
            child: OutlinedButton.icon(
              onPressed: _replayVideo,
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('Ver de nuevo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade400),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
        if (_isCompleted &&
            (widget.completionText?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Text(
              widget.completionText!.trim(),
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAchievementOverlay() {
    return AnimatedScale(
      duration: const Duration(milliseconds: 350),
      scale: _showAchievement ? 1 : 0.7,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: _showAchievement ? 1 : 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Logro desbloqueado',
                style: TextStyle(
                  color: Colors.white,
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
