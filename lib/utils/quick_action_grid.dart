/// Layout arithmetic for the dashboard's Quick Actions grid.
///
/// The grid used to be hand-laid as two rows of two plus one tile spanning the
/// full width, with each tile a row of icon, title, "Tap to open" and a
/// chevron. On a 360dp phone that left the title about 43dp to live in, so
/// "Tag Estimate" broke into "Tag Es / timat / e" and the tile it was in grew
/// taller than the tile beside it. Nothing in that layout responded to the
/// screen it was on — it simply failed more or less badly depending on width.
///
/// The replacement is a grid of identical tiles whose column count comes from
/// the width available. The sums live here, away from the widget tree, so the
/// behaviour at a given screen size can be checked rather than eyeballed on
/// one device.
library;

/// Gap between tiles, across and down.
const double kQuickActionGap = 10;

/// Narrowest a tile may be. Below this the two-word labels start breaking
/// mid-word again, which is the whole fault being fixed.
const double kQuickActionMinTileWidth = 84;

/// Widest a tile may be. Without a ceiling, five tiles stretched across a
/// tablet become five big empty cards with a small icon adrift in each.
///
/// Set so that the widths which would otherwise give four columns (a 480 to
/// 500dp screen) are instead forced down to three: four columns of five tiles
/// is a single orphan in the second row, the one arrangement worse than the
/// 2 + 2 + 1 it replaces.
const double kQuickActionMaxTileWidth = 150;

/// The hairline around each tile. It is drawn inside the tile's box, so it
/// takes height from the content — leaving it out of the sum gave every tile
/// a two-pixel overflow stripe along its bottom edge.
const double kQuickActionBorderWidth = 1;

const double kQuickActionIconSize = 44;
const double kQuickActionIconGap = 9;
const double kQuickActionVerticalPadding = 13;
const double kQuickActionLabelSize = 11.5;
const double kQuickActionLabelLeading = 1.25;

/// Lines reserved for every label, used whether or not the label needs them.
///
/// Reserving the space is what keeps the tiles the same height: a grid where
/// "Scan" is shorter than "WH Tag Estimate" is exactly the ragged look being
/// fixed.
const int kQuickActionLabelLines = 2;

/// Height of the label block, always [kQuickActionLabelLines] lines tall.
double quickActionLabelHeight() =>
    kQuickActionLabelSize * kQuickActionLabelLeading * kQuickActionLabelLines;

/// Height every tile gets, whatever its label.
double quickActionTileHeight() =>
    kQuickActionBorderWidth * 2 +
    kQuickActionVerticalPadding * 2 +
    kQuickActionIconSize +
    kQuickActionIconGap +
    quickActionLabelHeight();

/// How many tiles fit across [available] logical pixels.
///
/// As many as will fit without dropping under [minTile], never more than there
/// are tiles to place, and never so few that each would have to exceed
/// [maxTile] — on a tablet that rule is what turns a cramped three-up grid
/// into a single row of five.
///
/// Within that range the shape of the last row decides. Full rows win: six
/// tiles on a 430dp phone fit four across, but 4 + 2 looks like a grid with a
/// bite out of it where 3 + 3 looks finished, so three is chosen. Failing a
/// count that divides evenly, any count that does not strand a single tile
/// is taken over one that does — five tiles at 4 + 1 is the one arrangement
/// worse than the 2 + 2 + 1 this grid replaces, and 3 + 2 reads as a grid.
int quickActionColumns(
  double available, {
  int itemCount = 5,
  double gap = kQuickActionGap,
  double minTile = kQuickActionMinTileWidth,
  double maxTile = kQuickActionMaxTileWidth,
}) {
  if (itemCount <= 0 || available <= 0) return 1;
  final fits = ((available + gap) / (minTile + gap)).floor();
  final needed = ((available + gap) / (maxTile + gap)).ceil();
  final most = fits.clamp(1, itemCount);
  final fewest = needed.clamp(1, itemCount);
  if (fewest >= most) return fewest;

  for (var columns = most; columns >= fewest; columns--) {
    if (itemCount % columns == 0) return columns;
  }
  for (var columns = most; columns >= fewest; columns--) {
    if (itemCount % columns != 1) return columns;
  }
  return most;
}

/// Width of one tile in a [columns]-wide grid.
///
/// Capped at [maxTile]: past that the grid stops growing and sits to the left
/// of the space instead, which looks deliberate where enormous tiles do not.
double quickActionTileWidth(
  double available,
  int columns, {
  double gap = kQuickActionGap,
  double maxTile = kQuickActionMaxTileWidth,
}) {
  if (columns <= 0) return 0;
  final width = (available - gap * (columns - 1)) / columns;
  if (width <= 0) return 0;
  return width > maxTile ? maxTile : width;
}
