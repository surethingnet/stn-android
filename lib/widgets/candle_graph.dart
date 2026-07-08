import 'package:flutter/material.dart';

class CandleGraph extends StatelessWidget {
  final double score; // Expects a value between 0.0 and 100.0

  const CandleGraph({
    Key? key,
    required this.score,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the color theme based on score ranges
    Color scoreColor;
    if (score < 40.0) {
      scoreColor = const Color(0xFFFF3B30); // Critical Red
    } else if (score < 75.0) {
      scoreColor = const Color(0xFFFF9500); // Warning Amber
    } else {
      scoreColor = const Color(0xFF34C759); // Healthy Mint Green
    }

    final double clampedScore = score.clamp(0.0, 100.0);
    final double alignmentX = (clampedScore / 50.0) - 1.0; // Map 0..100 to -1..1 alignment

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score indicator labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Security Health',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${score.toStringAsFixed(0)}%',
              style: TextStyle(
                color: scoreColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: scoreColor.withOpacity(0.4),
                    blurRadius: 8,
                  )
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // The Candle Graph Bar
        Stack(
          alignment: Alignment.center,
          children: [
            // Track bar with smooth gradient
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF3B30), // Red
                    Color(0xFFFF9500), // Orange
                    Color(0xFF34C759), // Green
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // The Candle Indicator (gliding along the track)
            AnimatedAlign(
              alignment: Alignment(alignmentX, 0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              child: Container(
                width: 6,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withOpacity(0.8),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
