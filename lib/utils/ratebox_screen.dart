import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../provider/commonCompanyYearSelectionProvider.dart';
import 'images.dart';

class AnimatedRateBox extends StatefulWidget {
  final String todayGoldRate;
  final String todaySilverRate;
  final VoidCallback? onTap;

  const AnimatedRateBox({
    super.key,
    required this.todayGoldRate,
    required this.todaySilverRate,
    this.onTap,
  });

  @override
  State<AnimatedRateBox> createState() => _AnimatedRateBoxState();
}

class _AnimatedRateBoxState extends State<AnimatedRateBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Matches the brand colour used across every report screen.
  static const Color _primary = Color(0xFF006EB7);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.012).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coSName =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .CoSname;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primary.withValues(alpha: 0.5),
              _primary.withValues(alpha: 0.12),
            ],
          ),
          boxShadow: [
            // Negative spread keeps the glow hugging the card instead of
            // bleeding out into a visible coloured square behind it.
            BoxShadow(
              color: _primary.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -6,
            ),
          ],
        ),
        padding: const EdgeInsets.all(1.35),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.65),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primary,
                Color.lerp(_primary, const Color(0xFF0D47A1), 0.35)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20.65),
              onTap: widget.onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Image.asset(AppImage.gold, scale: 15),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  "Gold Rate${coSName == "UAE" ? "(AED)" : ""}",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.todayGoldRate,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        height: 52,
                        width: 1,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          Image.asset(AppImage.silver, scale: 15),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  "Silver Rate${coSName == "UAE" ? "(AED)" : ""}",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.todaySilverRate,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
