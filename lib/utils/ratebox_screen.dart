import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../provider/commonCompanyYearSelectionProvider.dart';
import 'images.dart';

class AnimatedRateBox extends StatefulWidget {
  final String todayGoldRate;
  final String todaySilverRate;

  const AnimatedRateBox({
    super.key,
    required this.todayGoldRate,
    required this.todaySilverRate,
  });

  @override
  State<AnimatedRateBox> createState() => _AnimatedRateBoxState();
}

class _AnimatedRateBoxState extends State<AnimatedRateBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true); // Continuous loop

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color(0xFF006EB7),
          boxShadow: [
            BoxShadow(
              color: Colors.blue[400]!,
              blurRadius: 12,
              spreadRadius: -5,
              offset: Offset(0, 5),
            )
          ],
        ),
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
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.todayGoldRate,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Container(
                height: 60,
                width: 1,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  SizedBox(width: 5),
                  Image.asset(AppImage.silver, scale: 15),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "Silver Rate${coSName == "UAE" ? "(AED)" : ""}",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.todaySilverRate,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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
    );
  }
}
