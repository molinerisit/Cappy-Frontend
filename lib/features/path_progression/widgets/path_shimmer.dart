import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class PathShimmer extends StatefulWidget {
  const PathShimmer({super.key});

  @override
  State<PathShimmer> createState() => _PathShimmerState();
}

class _PathShimmerState extends State<PathShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            _buildShimmerNode(),
            const SizedBox(height: 120),
            _buildShimmerNode(),
            const SizedBox(height: 120),
            _buildShimmerNode(),
            const SizedBox(height: 120),
            _buildShimmerNode(),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerNode() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.border,
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipOval(
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: const [
                              Colors.transparent,
                              Colors.white24,
                              Colors.transparent,
                            ],
                            stops: [
                              _animation.value - 0.3,
                              _animation.value,
                              _animation.value + 0.3,
                            ],
                          ).createShader(bounds);
                        },
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(6),
              ),
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [
                      Colors.transparent,
                      Colors.white24,
                      Colors.transparent,
                    ],
                    stops: [
                      _animation.value - 0.3,
                      _animation.value,
                      _animation.value + 0.3,
                    ],
                  ).createShader(bounds);
                },
                child: Container(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
