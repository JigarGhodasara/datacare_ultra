import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One figure in a summary banner: a caption, a number and an optional unit.
@immutable
class SummaryStat {
  final String label;
  final String value;

  /// Drawn smaller and lighter than the number, so the figure leads. A unit
  /// repeated at full size costs the digits room they need.
  final String? unit;

  /// Share of the row's width. Short whole numbers need less than a weight
  /// carrying four or five significant digits.
  final int flex;

  const SummaryStat(this.label, this.value, {this.unit, this.flex = 1});
}

/// Figures laid out across a coloured summary banner, separated by rules.
///
/// Splitting the width equally between a piece count and two weights starved
/// the weights while leaving the count's column half empty, so each stat
/// carries its own [SummaryStat.flex].
class SummaryStatRow extends StatelessWidget {
  final List<SummaryStat> stats;

  const SummaryStatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const _StatDivider(),
            Expanded(flex: stats[i].flex, child: _Stat(stats[i])),
          ],
        ],
      ),
    );
  }
}

/// Vertical rule between two figures.
///
/// The margin is the point: without it the rule sits hard against the next
/// label, which is what makes a banner look cramped.
class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
      color: Colors.white.withValues(alpha: 0.22),
    );
  }
}

class _Stat extends StatelessWidget {
  final SummaryStat stat;

  const _Stat(this.stat);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: Colors.white.withValues(alpha: 0.82))),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: stat.value,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: Colors.white),
                ),
                if (stat.unit != null)
                  TextSpan(
                    text: ' ${stat.unit}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
