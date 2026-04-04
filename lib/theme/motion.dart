import 'package:flutter/animation.dart';

class AppMotionDurations {
  AppMotionDurations._();

  static const micro = Duration(milliseconds: 100);
  static const quick = Duration(milliseconds: 150);
  static const short = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 300);
  static const emphasis = Duration(milliseconds: 400);
  static const feedbackSuccess = Duration(milliseconds: 280);
  static const feedbackError = Duration(milliseconds: 420);
  static const entrance = Duration(milliseconds: 650);
  static const celebrationEntrance = Duration(milliseconds: 520);
  static const pageEntrance = Duration(milliseconds: 800);
  static const long = Duration(milliseconds: 1200);
  static const xpCount = Duration(milliseconds: 1000);
  static const pulse = Duration(milliseconds: 2000);
  static const shimmer = Duration(milliseconds: 1500);
  static const celebration = Duration(milliseconds: 2200);
  static const confettiBurst = Duration(milliseconds: 1800);
  static const hold = Duration(milliseconds: 500);
  static const interactionPreview = Duration(seconds: 2);
}

class AppMotionCurves {
  AppMotionCurves._();

  static const tap = Curves.easeInOut;
  static const feedback = Curves.easeOut;
  static const entrance = Curves.easeOutCubic;
  static const entranceSoft = Curves.easeOut;
  static const bounce = Curves.elasticOut;
  static const emphasis = Curves.easeOutBack;
  static const pulse = Curves.easeInOut;
}

class AppMotionValues {
  AppMotionValues._();

  static const pressedScale = 0.98;
  static const pressedStrongScale = 0.96;
  static const buttonPressedScale = 0.95;
  static const pulseScale = 1.02;
  static const introScaleStart = 0.5;
  static const dialogScaleStart = 0.88;
  static const subtleSlideOffset = 0.05;
  static const standardSlideOffset = 0.08;
  static const shakeDistance = 12.0;
}
