/// How the Other Details table reports the quantity of a stone.
///
/// The rows come from BAR_IDTL, where a stone is entered either by piece count
/// (IT_PCS) or by carat weight (IT_GWT) — rarely both. Printing both columns
/// always meant every row carried a "0" in whichever one was not used, which
/// read as a real zero rather than "not applicable".
enum OtherQtyMode {
  /// Show whichever of the two the operator actually entered, per row.
  auto('Auto'),

  /// Always report the piece count.
  pieces('Pieces'),

  /// Always report the carat weight.
  weight('Weight');

  const OtherQtyMode(this.label);
  final String label;
}

double _num(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;

/// Column heading for the quantity column.
///
/// Under [OtherQtyMode.auto] the rows can disagree with each other, so the
/// heading stays neutral and each value carries its own unit instead.
String otherQtyHeader(OtherQtyMode mode) {
  switch (mode) {
    case OtherQtyMode.auto:
      return 'Qty';
    case OtherQtyMode.pieces:
      return 'Pcs';
    case OtherQtyMode.weight:
      return 'Ct Wt';
  }
}

/// The quantity cell for one BAR_IDTL row.
///
/// In [OtherQtyMode.auto] the piece count wins when both are present: a stone
/// counted in pieces is how it was sold, and the weight is supporting detail.
/// A row with neither reads as "-" rather than "0", so an unfilled entry is
/// not mistaken for a zero-weight stone.
String otherQtyText(dynamic row, OtherQtyMode mode) {
  final pcs = _num(row is Map ? row['IT_PCS'] : null);
  final wt = _num(row is Map ? row['IT_GWT'] : null);

  switch (mode) {
    case OtherQtyMode.pieces:
      return pcs > 0 ? pcs.toStringAsFixed(0) : '-';
    case OtherQtyMode.weight:
      return wt > 0 ? wt.toStringAsFixed(2) : '-';
    case OtherQtyMode.auto:
      // Units are spelled out because neighbouring rows may be measured
      // differently and the shared heading cannot say which is which.
      if (pcs > 0) return '${pcs.toStringAsFixed(0)} pc';
      if (wt > 0) return '${wt.toStringAsFixed(2)} ct';
      return '-';
  }
}
