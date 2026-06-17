import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import '../config/theme.dart';

/// Brand-coloured pull-to-refresh wrapper.
/// Shows the Moon piccolo accent spinner with "Memuat..." text below
/// while the user holds. Internally uses a standard [RefreshIndicator]
/// so platform behaviour and accessibility stay intact.
class PremiumRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? backgroundColor;

  const PremiumRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return RefreshIndicator(
      color: SAMsTheme.accent,
      backgroundColor: backgroundColor ?? t.scaffoldBackgroundColor,
      strokeWidth: 2.6,
      displacement: 56,
      semanticsLabel: 'Memuat...',
      semanticsValue: 'Memuat...',
      onRefresh: onRefresh,
      child: child,
    );
  }
}

/// Counts a numeric value up from 0 to [value] using easeOutCubic over
/// 1200ms and renders it formatted as Malaysian Ringgit currency.
class AnimatedBalanceText extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final String symbol;
  final int decimals;
  final Duration duration;

  const AnimatedBalanceText({
    super.key,
    required this.value,
    this.style,
    this.symbol = 'RM ',
    this.decimals = 2,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<AnimatedBalanceText> createState() => _AnimatedBalanceTextState();
}

class _AnimatedBalanceTextState extends State<AnimatedBalanceText> {
  bool _hasAnimatedOnce = false;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      symbol: widget.symbol,
      decimalDigits: widget.decimals,
      locale: 'en_MY',
    );
    if (!_hasAnimatedOnce) {
      _hasAnimatedOnce = true;
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: widget.value),
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Text(
          fmt.format(v),
          style: widget.style ??
              GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
    }
    return Text(
      fmt.format(widget.value),
      style: widget.style ??
          GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

/// Counts an integer up from 0 to [value]. Used for stat counters.
class AnimatedIntText extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;
  final int decimals;

  const AnimatedIntText({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1200),
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(
        '$prefix${v.toStringAsFixed(decimals)}$suffix',
        style: style,
      ),
    );
  }
}

/// Smooth crossfade currency text (no shake/vibrate). Uses AnimatedSwitcher
/// with fade transition instead of flip animation. Recommended for payment
/// screens where amount changes frequently.
class CrossfadeCurrencyText extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String prefix;
  final int fractionDigits;

  const CrossfadeCurrencyText({
    super.key,
    required this.value,
    this.style,
    this.prefix = 'RM ',
    this.fractionDigits = 2,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Text(
        '$prefix${NumberFormat.currency(locale: 'en_MY', symbol: '', decimalDigits: fractionDigits).format(value)}',
        key: ValueKey<double>(value),
        style: style,
      ),
    );
  }
}

/// Premium flip-style currency counter (e.g. "RM 1,234.56"). Each digit
/// flips like an odometer when [value] changes — far more tactile than a
/// plain tween. Uses `animated_flip_counter` under the hood with the
/// Malaysian thousands separator.
class FlipCurrencyText extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final int fractionDigits;

  const FlipCurrencyText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.prefix = 'RM ',
    this.fractionDigits = 2,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedFlipCounter(
      value: value,
      duration: duration,
      curve: curve,
      prefix: prefix,
      fractionDigits: fractionDigits,
      thousandSeparator: ',',
      textStyle: style,
    );
  }
}

/// Premium flip-style integer counter for stat numbers (student counts,
/// days remaining, totals, etc).
class FlipIntText extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final String suffix;

  const FlipIntText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedFlipCounter(
      value: value,
      duration: duration,
      curve: curve,
      prefix: prefix,
      suffix: suffix,
      thousandSeparator: ',',
      textStyle: style,
    );
  }
}

/// Glassmorphism card. ClipRRect with smooth iOS-like radius wraps a
/// BackdropFilter blurring everything behind the child. The surface
/// itself is a translucent overlay so the blur reads through.
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double cornerRadius;
  final double blurSigma;
  final Color? tint;
  final Color? borderColor;
  final double borderWidth;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.cornerRadius = 16,
    this.blurSigma = 20,
    this.tint,
    this.borderColor,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = tint ??
        (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.55));
    final border = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.6));

    return ClipRRect(
      borderRadius: SmoothBorderRadius(
        cornerRadius: cornerRadius,
        cornerSmoothing: 0.8,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: ShapeDecoration(
            color: overlay,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: cornerRadius,
                cornerSmoothing: 0.8,
              ),
              side: BorderSide(color: border, width: borderWidth),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
