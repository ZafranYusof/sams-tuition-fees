import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget? nextScreen;
  const SplashScreen({super.key, this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeIn = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _slide = Tween<double>(begin: 14, end: 0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0, 0.85, curve: Curves.easeOutCubic)));
    _controller.forward();

    // Only navigate if nextScreen is provided (legacy usage)
    if (widget.nextScreen != null) {
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (mounted) {
          Navigator.pushReplacement(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.nextScreen!,
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ));
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SAMsTheme.ink,
      body: Stack(
        children: [
          // Subtle radial vignette in brass — replaces the rainbow gradient.
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.3, -0.4),
                  radius: 1.2,
                  colors: [Color(0x33C9A961), Color(0x000B1B2C)],
                ),
              ),
            ),
          ),
          // Editorial logotype lockup, centered.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Opacity(
              opacity: _fadeIn.value,
              child: Transform.translate(
                offset: Offset(0, _slide.value),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Brass rule above
                      Container(width: 36, height: 1, color: SAMsTheme.brass),
                      const SizedBox(height: 14),
                      Text(
                        'SAMs',
                        style: GoogleFonts.fraunces(
                          color: SAMsTheme.paper,
                          fontSize: 56,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Student Academic Management',
                        style: GoogleFonts.inter(
                          color: SAMsTheme.paper.withOpacity(0.65),
                          fontSize: 11.5,
                          letterSpacing: 2.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      // Footer mark — refined, not centered hero.
                      Padding(
                        padding: const EdgeInsets.only(bottom: 36),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.2,
                                color: SAMsTheme.brass.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'UMPSA',
                              style: GoogleFonts.inter(
                                color: SAMsTheme.paper.withOpacity(0.5),
                                fontSize: 10,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
