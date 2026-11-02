import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../provider/commonCompanyYearSelectionProvider.dart';
import 'colors.dart';

class CashOnHandBox extends StatelessWidget {
  final String cashAmount;

  const CashOnHandBox({
    super.key,
    required this.cashAmount,
  });

  static const Color _ink = Color(0xFF1E293B);

  /// Formats the balance to three decimals.
  ///
  /// The value arrives as `SUM(...).toString()` straight off the driver, which
  /// renders a double at full precision — so a balance could show as
  /// `123456.78901234567` and overflow the card. Non-numeric or blank values
  /// are passed through untouched rather than shown as "0.000", so a genuine
  /// load failure stays visible instead of looking like an empty till.
  static String formatAmount(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return text;
    final parsed = double.tryParse(text);
    if (parsed == null) return text;
    return parsed.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    final coSName =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .CoSname;
    const primary = Color(0xFF006EB7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withValues(alpha: 0.2),
              AppColor.goldenColor.withValues(alpha: 0.35),
            ],
          ),
          boxShadow: [
            // Negative spread keeps the glow hugging the card instead of
            // bleeding out into a visible coloured square behind it.
            BoxShadow(
              color: primary.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(1.35),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.65),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE8D5A0),
                AppColor.goldenColor,
                const Color(0xFFC9A227).withValues(alpha: 0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 9,
                offset: const Offset(0, 3),
                spreadRadius: -3,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Cash on Hand ${coSName == "UAE" ? "(AED)" : ""}",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: _ink.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${formatAmount(cashAmount).replaceAll('-', '')} ${cashAmount.contains('-') ? "Dr" : "Cr"}",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
