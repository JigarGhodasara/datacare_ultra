import 'package:DataCareUltra/utils/rank_list_metrics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Matching the Graph Reports palette. Copied rather than imported, as
// voucher_chip.dart does, because the screens keep their tokens private.
const Color _textPrimary = Color(0xFF0F172A);
const Color _textSecondary = Color(0xFF64748B);
const Color _hairline = Color(0xFFEEF2F6);

/// One ranked row: a name, the figure it is ranked by, and an optional
/// second line (pieces sold, a mobile number, a city).
@immutable
class RankEntry {
  final String name;
  final double value;
  final String subtitle;

  /// Printed instead of the formatted [value] when the figure the row ranks by
  /// is not the figure worth showing — an item sold with no weight entered
  /// ranks at zero grams but should still read "4 pcs", not "0.000 gm".
  final String? display;

  const RankEntry(this.name, this.value, {this.subtitle = '', this.display});
}

/// A ranked list holding every row, scrolling inside a fixed window.
///
/// These lists used to stop at five rows, which was all the card had room for;
/// a shop with forty items could not see item six at all. Scrolling the rows
/// inside the card keeps the card the height it already was and still gives
/// the user everything.
///
/// A list that scrolls inside a page that also scrolls has to announce itself,
/// or it reads as a list that simply ends. Three things do that here: the next
/// row left peeking out below the window (see [rankViewportHeight]), a
/// scrollbar that stays visible instead of fading away, and a fade at
/// whichever edge still has rows beyond it.
class RankList extends StatefulWidget {
  final List<RankEntry> rows;

  /// Colour of the rank badges, figures and bars — one per list, so the four
  /// lists on a page stay distinguishable while scrolling.
  final Color accent;

  /// Turns a row's value into the figure shown on its right.
  final String Function(double) format;

  const RankList({
    super.key,
    required this.rows,
    required this.accent,
    required this.format,
  });

  @override
  State<RankList> createState() => _RankListState();
}

class _RankListState extends State<RankList> {
  final ScrollController _controller = ScrollController();

  /// Which edges still have rows beyond them. Fading an edge with nothing past
  /// it would dim the first or last row for no reason.
  bool _atTop = true;
  bool _atBottom = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final top = position.pixels <= 1;
    final bottom = position.pixels >= position.maxScrollExtent - 1;
    if (top != _atTop || bottom != _atBottom) {
      setState(() {
        _atTop = top;
        _atBottom = bottom;
      });
    }
  }

  /// Masks the top and bottom of the window so rows dissolve at the edges
  /// rather than being chopped through the middle of a glyph.
  Shader _edgeFade(Rect bounds) {
    final fade = (16 / bounds.height).clamp(0.0, 0.3);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _atTop ? Colors.white : Colors.transparent,
        Colors.white,
        Colors.white,
        _atBottom ? Colors.white : Colors.transparent,
      ],
      stops: [0, fade, 1 - fade, 1],
    ).createShader(bounds);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) return const SizedBox.shrink();
    final scrolls = rankListScrolls(widget.rows.length);
    // The leader sets the length of every bar, so the gap between first and
    // last is readable without comparing the figures.
    final leaderValue = widget.rows.first.value;

    final list = ListView.builder(
      controller: _controller,
      physics: scrolls
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      // Room on the right for the scrollbar, so it does not sit on the figures.
      padding: EdgeInsets.only(right: scrolls ? 8 : 0),
      itemExtent: kRankRowExtent,
      itemCount: widget.rows.length,
      itemBuilder: (_, i) => RankRow(
        position: i + 1,
        row: widget.rows[i],
        accent: widget.accent,
        share: leaderValue <= 0 ? 0 : widget.rows[i].value / leaderValue,
        figure: widget.rows[i].display ?? widget.format(widget.rows[i].value),
      ),
    );

    return SizedBox(
      height: rankViewportHeight(widget.rows.length),
      child: scrolls
          ? Scrollbar(
              controller: _controller,
              thumbVisibility: true,
              thickness: 3,
              radius: const Radius.circular(3),
              child: ShaderMask(
                shaderCallback: _edgeFade,
                blendMode: BlendMode.dstIn,
                child: list,
              ),
            )
          : list,
    );
  }
}

/// One row of a [RankList]: position, name, sub-line, figure and share bar.
///
/// The figure sits on the name's line rather than in a column of its own,
/// which lets the bar run the full width of the row — on a list of forty rows
/// the bar is what makes the shape of the ranking visible while scrolling.
///
/// Every text style here pins its line height, because the row has to fit
/// [kRankRowExtent] exactly: a list laid out by itemExtent gives a row no
/// extra space, and a font whose default leading is a shade taller would
/// overflow instead of growing.
class RankRow extends StatelessWidget {
  final int position;
  final RankEntry row;
  final Color accent;

  /// This row's value as a fraction of the leader's, 0 to 1.
  final double share;

  /// Already-formatted figure for the right of the name line.
  final String figure;

  const RankRow({
    super.key,
    required this.position,
    required this.row,
    required this.accent,
    required this.share,
    required this.figure,
  });

  @override
  Widget build(BuildContext context) {
    // The top three are tinted harder. On a list that now runs to dozens of
    // rows, the leaders have to stay findable after scrolling back up.
    final leader = position <= 3;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: leader ? 0.16 : 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$position',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: accent)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(row.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    Text(figure,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: accent)),
                  ],
                ),
                if (row.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(row.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary)),
                ],
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: _hairline,
                    valueColor: AlwaysStoppedAnimation(
                        accent.withValues(alpha: leader ? 1 : 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
