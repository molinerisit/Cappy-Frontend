import 'package:flutter/material.dart';
import 'dart:math' as math;

class EarthPlanetWidget extends StatefulWidget {
  final String? countryName;
  final String? countryFlag;
  final VoidCallback? onComplete;

  const EarthPlanetWidget({
    super.key,
    this.countryName,
    this.countryFlag,
    this.onComplete,
  });

  @override
  State<EarthPlanetWidget> createState() => _EarthPlanetWidgetState();
}

class _EarthPlanetWidgetState extends State<EarthPlanetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Scale animation: 0 -> 1
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    // Opacity animation: 0 -> 1 -> 1 -> 0
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // Rotation animation: 0 -> 3 turns
    _rotationAnimation = Tween<double>(begin: 0.0, end: 3.0 * 2 * math.pi)
        .animate(
          CurvedAnimation(
            parent: _rotationController,
            curve: const Interval(0.1, 0.9, curve: Curves.linear),
          ),
        );

    _rotationController.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: RotationTransition(
            turns: _rotationAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade400.withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),

                // Planet container with gradient
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade300, Colors.blue.shade600],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ocean waves pattern
                      CustomPaint(
                        painter: OceanPainter(),
                        size: const Size(280, 280),
                      ),

                      // Continents (simplified)
                      CustomPaint(
                        painter: ContinentsPainter(),
                        size: const Size(280, 280),
                      ),

                      // Country highlight (if provided)
                      if (widget.countryName != null)
                        CustomPaint(
                          painter: CountryHighlightPainter(
                            countryName: widget.countryName ?? '',
                          ),
                          size: const Size(280, 280),
                        ),
                    ],
                  ),
                ),

                // Flag animation above planet
                if (widget.countryFlag != null &&
                    widget.countryFlag!.isNotEmpty)
                  Positioned(
                    top: -60,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _rotationController,
                          curve: const Interval(
                            0.5,
                            1.0,
                            curve: Curves.elasticOut,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.countryFlag!,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OceanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw wave patterns
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      path.addOval(
        Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: radius * (0.3 + i * 0.25),
        ),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(OceanPainter oldDelegate) => false;
}

class ContinentsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade600
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Simplified continents - North America
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX * 0.5, centerY * 0.6),
        width: 60,
        height: 80,
      ),
      paint,
    );

    // South America
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX * 0.55, centerY * 1.3),
        width: 40,
        height: 60,
      ),
      paint,
    );

    // Africa
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX * 1.1, centerY),
        width: 50,
        height: 80,
      ),
      paint,
    );

    // Europe
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX * 1.05, centerY * 0.65),
        width: 35,
        height: 35,
      ),
      paint,
    );

    // Asia
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX * 1.2, centerY * 0.7),
        width: 70,
        height: 70,
      ),
      paint,
    );

    // Australia
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX * 1.35, centerY * 1.15),
        width: 30,
        height: 35,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(ContinentsPainter oldDelegate) => false;
}

class CountryHighlightPainter extends CustomPainter {
  final String countryName;

  CountryHighlightPainter({required this.countryName});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.shade400.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Highlight country based on name
    switch (countryName.toLowerCase()) {
      case 'mexico':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX * 0.5, centerY * 0.6),
            width: 60,
            height: 80,
          ),
          paint,
        );
        break;
      case 'spain':
      case 'españa':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX * 1.02, centerY * 0.62),
            width: 25,
            height: 30,
          ),
          paint,
        );
        break;
      case 'italy':
      case 'italia':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX * 1.08, centerY * 0.68),
            width: 15,
            height: 35,
          ),
          paint,
        );
        break;
      case 'france':
      case 'francia':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX * 0.98, centerY * 0.58),
            width: 30,
            height: 35,
          ),
          paint,
        );
        break;
      case 'japan':
      case 'japón':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX * 1.4, centerY * 0.7),
            width: 20,
            height: 40,
          ),
          paint,
        );
        break;
      case 'thailand':
      case 'tailandia':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX * 1.25, centerY * 0.95),
            width: 20,
            height: 30,
          ),
          paint,
        );
        break;
      case 'argentina':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX * 0.55, centerY * 1.3),
            width: 40,
            height: 60,
          ),
          paint,
        );
        break;
      case 'india':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX * 1.18, centerY * 0.92),
            width: 25,
            height: 40,
          ),
          paint,
        );
        break;
      case 'china':
      case 'adiós':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX * 1.25, centerY * 0.65),
            width: 35,
            height: 40,
          ),
          paint,
        );
        break;
      default:
        // Default highlight
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX * 1.1, centerY),
            width: 50,
            height: 80,
          ),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(CountryHighlightPainter oldDelegate) {
    return oldDelegate.countryName != countryName;
  }
}
