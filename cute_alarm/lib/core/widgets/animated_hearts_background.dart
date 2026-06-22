import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A decorative layer of softly floating, fading, rotating hearts.
/// Designed to sit behind foreground content via a [Stack].
class AnimatedHeartsBackground extends StatefulWidget {
  final int heartCount;
  final List<Color>? colors;
  final double maxSize;
  final double minSize;

  const AnimatedHeartsBackground({
    super.key,
    this.heartCount = 18,
    this.colors,
    this.maxSize = 32,
    this.minSize = 12,
  });

  @override
  State<AnimatedHeartsBackground> createState() =>
      _AnimatedHeartsBackgroundState();
}

class _HeartSpec {
  final double startX; // 0..1 fraction of width
  final double size;
  final double speed; // seconds per full vertical traverse
  final double delay; // seconds before it starts
  final double sway; // horizontal sway amplitude in fraction of width
  final double swayFrequency;
  final Color color;
  final double opacity;

  _HeartSpec({
    required this.startX,
    required this.size,
    required this.speed,
    required this.delay,
    required this.sway,
    required this.swayFrequency,
    required this.color,
    required this.opacity,
  });
}

class _AnimatedHeartsBackgroundState extends State<AnimatedHeartsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_HeartSpec> _hearts;

  @override
  void initState() {
    super.initState();
    final random = Random();
    final palette = widget.colors ??
        const [
          AppColors.primaryPink,
          AppColors.softPink,
          AppColors.heartRed,
          AppColors.lavender,
        ];

    _hearts = List.generate(widget.heartCount, (i) {
      return _HeartSpec(
        startX: random.nextDouble(),
        size: widget.minSize +
            random.nextDouble() * (widget.maxSize - widget.minSize),
        speed: 8 + random.nextDouble() * 10, // 8-18s per loop
        delay: random.nextDouble() * 10,
        sway: 0.04 + random.nextDouble() * 0.08,
        swayFrequency: 1 + random.nextDouble() * 2,
        color: palette[random.nextInt(palette.length)],
        opacity: 0.25 + random.nextDouble() * 0.45,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final elapsed =
                  _controller.lastElapsedDuration?.inMilliseconds ?? 0;
              final t = elapsed / 1000.0;
              return Stack(
                children: _hearts.map((h) {
                  final localT = (t + h.delay) % h.speed;
                  final progress = localT / h.speed; // 0..1
                  final y =
                      constraints.maxHeight * (1 - progress) - h.size;
                  final sway = sin(progress * 2 * pi * h.swayFrequency) *
                      h.sway *
                      constraints.maxWidth;
                  final x = h.startX * constraints.maxWidth + sway;
                  final fadeOpacity = progress < 0.1
                      ? progress / 0.1
                      : progress > 0.85
                          ? (1 - progress) / 0.15
                          : 1.0;

                  return Positioned(
                    left: x.clamp(0, constraints.maxWidth - h.size),
                    top: y.clamp(-h.size, constraints.maxHeight),
                    child: Opacity(
                      opacity:
                          (h.opacity * fadeOpacity).clamp(0.0, 1.0),
                      child: Icon(
                        Icons.favorite,
                        size: h.size,
                        color: h.color,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
