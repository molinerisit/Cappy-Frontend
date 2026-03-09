import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/image_optimize_service.dart';

class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius? borderRadius;
  final Widget? errorFallback;
  final Widget? placeholder;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.errorFallback,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final optimizedUrl = ImageOptimizeService.optimizeUrl(imageUrl);

    Widget imageWidget = CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      placeholder: (_, __) =>
          placeholder ??
          _ShimmerImagePlaceholder(
            width: width,
            height: height,
            borderRadius: borderRadius,
          ),
      errorWidget: (_, __, ___) =>
          errorFallback ?? _ImageErrorFallback(width: width, height: height),
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }
}

class _ImageErrorFallback extends StatelessWidget {
  final double? width;
  final double? height;

  const _ImageErrorFallback({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFF94A3B8),
        size: 36,
      ),
    );
  }
}

class _ShimmerImagePlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const _ShimmerImagePlaceholder({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_ShimmerImagePlaceholder> createState() =>
      _ShimmerImagePlaceholderState();
}

class _ShimmerImagePlaceholderState extends State<_ShimmerImagePlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(10);

    return ClipRRect(
      borderRadius: radius,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment(-1 + (_controller.value * 2), -0.3),
                end: Alignment(1 + (_controller.value * 2), 0.3),
                colors: const [
                  Color(0xFFE2E8F0),
                  Color(0xFFF8FAFC),
                  Color(0xFFE2E8F0),
                ],
              ).createShader(rect);
            },
            child: Container(
              width: widget.width,
              height: widget.height,
              color: const Color(0xFFE2E8F0),
            ),
          );
        },
      ),
    );
  }
}
