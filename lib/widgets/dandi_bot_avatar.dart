import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DandiBotAvatar extends StatelessWidget {
  const DandiBotAvatar({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.blueBright.withValues(alpha: 0.85),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 1.5,
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/logo.jpg'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
