import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StarRatingWidget extends StatelessWidget {
  final int rating;
  final Function(int) onRatingChanged;
  final double size;
  final Color? color;

  const StarRatingWidget({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starIndex == rating ? 0 : starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Icon(
              starIndex <= rating
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: color ?? AppTheme.appleMusicRed,
            ),
          ),
        );
      }),
    );
  }
}
