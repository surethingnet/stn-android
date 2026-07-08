import 'package:flutter/material.dart';

class WifiWarningOverlay extends StatelessWidget {
  final bool isVisible;

  const WifiWarningOverlay({
    Key? key,
    required this.isVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button dismissal
      child: Material(
        color: Colors.black.withOpacity(0.92), // Dark dim effect
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pulsing Wi-Fi alert icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(seconds: 2),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                onEnd: () {}, // Trigger rebuild for infinite pulse if needed (simplified here)
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withOpacity(0.15), // Translucent Amber
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF9500).withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 64,
                    color: Color(0xFFFF9500),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Wi-Fi Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'SureThingNet audits network safety by communicating with local devices. You must connect to your home or office Wi-Fi network to run the auditor.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Visual connection helper indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[600]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Waiting for connection...',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
