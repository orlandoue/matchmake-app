import 'package:flutter/material.dart';

/// Premium gold for filled division-progress stars (Pokémon-Unite style).
const Color kRatingGold = Color(0xFFFFD54A);

/// A compact row of division-progress stars (default max = 4, the business
/// rule). Filled stars use a premium gold; empty ones a muted translucent
/// tone that reads well on both dark and light surfaces.
class StarRatingRow extends StatelessWidget {
  final int stars;
  final int max;
  final double size;
  final double gap;
  final Color filledColor;
  final Color emptyColor;

  const StarRatingRow({
    super.key,
    required this.stars,
    this.max = 4,
    this.size = 24,
    this.gap = 6,
    this.filledColor = kRatingGold,
    this.emptyColor = const Color(0x40000000),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final filled = i < stars;
        return Padding(
          padding: EdgeInsets.only(right: i == max - 1 ? 0 : gap),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: filled ? filledColor : emptyColor,
            size: size,
          ),
        );
      }),
    );
  }
}
