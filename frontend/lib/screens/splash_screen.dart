import 'dart:math';
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
  late AnimationController _mainController;
  late AnimationController _dotController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late Animation<double> _fadeIn;
  late Animation<double> _slide;
  late Animation<double> _scaleAnim;
  late Animation<double> _lineWidth;
  late Animation<double> _shimmerAnim;
  late List<Animation<double>> _dotAnimations;

  // Floating particles
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();

    // Generate particles
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 1.5 + _random.nextDouble() * 2.5,
        speed: 0.2 + _random.nextDouble() * 0.6,
        opacity: 0.1 + _random.nextDouble() * 0.3,
      ));
    }

    // Main entrance animation
    _mainController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _fadeIn = CurvedAnimation(parent: _mainController, curve: const Interval(0, 0.5, curve: Curves.easeOut));
    _slide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0, 0.6, curve: Curves.easeOutCubic)),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.1, 0.7, curve: Curves.elasticOut)),
    );
    _lineWidth = Tween<double>(begin: 0, end: 36).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)),
    );
    _mainController.forward();

    // Shimmer on text (loops)
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Particle float animation (loops)
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    // Subtle pulse on logo (loops)
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    // Three-dot pulse animation
    _dotController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _dotAnimations = List.generate(3, (index) {
      final start = (index * 200) / 1200;
      final peak = start + 0.167;
      final end = (peak + 0.167).clamp(0.0, 1.0);
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: start * 100),
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: (peak - start) * 100),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: (end - peak) * 100),
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: (1.0 - end) * 100),
      ]).animate(_dotController);
    });

    // Navigate after splash
    if (widget.nextScreen != null) {
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) {
          Navigator.pushReplacement(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.nextScreen!,
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ));
        }
      });
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _dotController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SAMsTheme.ink,
      body: Stack(
        children: [
          // Animated radial gradient background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    radius: 1.0 + (_pulseController.value * 0.3),
                    colors: [
                      Color.lerp(const Color(0x22C9A961), const Color(0x44C9A961), _pulseController.value)!,
                      const Color(0x000B1B2C),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (_, __) => CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              ),
            ),
          ),

          // Main content
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, _) => Opacity(
              opacity: _fadeIn.value,
              child: Transform.translate(
                offset: Offset(0, _slide.value),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // UMPSA Logo
                      Container(
                        width: 170, height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: SAMsTheme.brass.withOpacity(0.3), width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/umpsa-logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Animated brass line (expands from center)
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (_, __) => Container(
                          width: _lineWidth.value,
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                SAMsTheme.brass.withOpacity(0),
                                SAMsTheme.brass,
                                SAMsTheme.brass.withOpacity(0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SAMs text with shimmer + scale bounce
                      Transform.scale(
                        scale: _scaleAnim.value,
                        child: AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (_, __) => ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment(_shimmerAnim.value - 1, 0),
                              end: Alignment(_shimmerAnim.value, 0),
                              colors: const [
                                Color(0xFFF5ECD7),
                                Color(0xFFC9A961),
                                Color(0xFFF5ECD7),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ).createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              'SAMs',
                              style: GoogleFonts.fraunces(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -2,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle with staggered fade
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (_, val, child) => Opacity(
                          opacity: val,
                          child: Transform.translate(
                            offset: Offset(0, 8 * (1 - val)),
                            child: child,
                          ),
                        ),
                        child: Text(
                          'Tuition & Fee Management',
                          style: GoogleFonts.inter(
                            color: SAMsTheme.paper.withOpacity(0.65),
                            fontSize: 11.5,
                            letterSpacing: 2.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.only(bottom: 36),
                        child: Column(
                          children: [
                            _buildPulsingDots(),
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
                            const SizedBox(height: 4),
                            Text(
                              'v1.0.0',
                              style: GoogleFonts.inter(
                                color: SAMsTheme.paper.withOpacity(0.3),
                                fontSize: 9,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w400,
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

  Widget _buildPulsingDots() {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final val = _dotAnimations[index].value;
          final scale = 0.5 + (val * 0.5);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.scale(
              scale: scale,
              child: Transform.translate(
                offset: Offset(0, -3 * val), // bounce up
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: SAMsTheme.brass.withOpacity(0.6 + (val * 0.4)),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SAMsTheme.brass.withOpacity(val * 0.4),
                        blurRadius: 6 * val,
                        spreadRadius: 1 * val,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// --- Particle model ---
class _Particle {
  double x, y, size, speed, opacity;
  _Particle({required this.x, required this.y, required this.size, required this.speed, required this.opacity});
}

// --- Particle painter ---
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - progress * p.speed) % 1.0;
      final x = p.x + sin(progress * 2 * pi + p.y * 6) * 0.02;
      final paint = Paint()
        ..color = const Color(0xFFC9A961).withOpacity(p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
