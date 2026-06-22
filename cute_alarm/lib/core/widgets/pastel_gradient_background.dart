import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PastelGradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const PastelGradientBackground({
    super.key,
    required this.child,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ?? AppColors.backgroundGradient,
        ),
      ),
      child: child,
    );
  }
}
