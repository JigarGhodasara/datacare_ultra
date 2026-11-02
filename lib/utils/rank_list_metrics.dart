/// Sizing rules for the ranked insight lists on the Graph Reports screen.
///
/// The lists used to be cut to the top five so the card would fit on screen.
/// They now hold every row and scroll inside a fixed window instead, which
/// means the window height has to be worked out rather than hard-coded — and
/// since it is arithmetic the screen depends on, it lives here where it can be
/// tested without building a widget.
library;

/// Height of one ranked row: rank badge, name, sub-line and the share bar.
const double kRankRowExtent = 58;

/// Rows visible at once. Five keeps the card the size it was before the lists
/// became scrollable, so the page does not suddenly grow.
const double kRankVisibleRows = 5;

/// Fraction of a row left showing beyond the window when the list is longer
/// than it.
///
/// A list that scrolls inside a page that also scrolls gives the user no cue
/// that it moves at all. Letting the next row peek out is that cue — big
/// enough to read as a cut-off row, small enough not to look like a layout
/// mistake.
const double kRankPeekFraction = 0.38;

/// Height of the scrolling window for a list of [rowCount] rows.
///
/// Short lists get exactly the height they need: a half-empty window under
/// three rows reads as data that failed to load. Longer lists are capped, plus
/// the peek.
double rankViewportHeight(
  int rowCount, {
  double rowExtent = kRankRowExtent,
  double visibleRows = kRankVisibleRows,
  double peekFraction = kRankPeekFraction,
}) {
  if (rowCount <= 0) return 0;
  final content = rowCount * rowExtent;
  final cap = visibleRows * rowExtent;
  if (content <= cap) return content;
  return cap + rowExtent * peekFraction;
}

/// Whether a list of [rowCount] rows is taller than its window, and so has
/// rows the user can only reach by scrolling.
bool rankListScrolls(
  int rowCount, {
  double rowExtent = kRankRowExtent,
  double visibleRows = kRankVisibleRows,
  double peekFraction = kRankPeekFraction,
}) {
  final height = rankViewportHeight(rowCount,
      rowExtent: rowExtent,
      visibleRows: visibleRows,
      peekFraction: peekFraction);
  return rowCount * rowExtent > height;
}
