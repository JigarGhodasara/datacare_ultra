/// The three views of tag movement in the Tag Stock Report.
///
/// All three read the same join of MAIN_STOCK / BAR_DETL / ITEM_MAST and
/// differ only in which rows they keep, so the figures stay consistent between
/// them: a tag that shows under "In" and later under "Out" is the same row,
/// counted once each way.
enum TagStockSection {
  /// Tags taken into stock in the chosen period — bought in or received.
  inTag('In Tag', 'Tags added'),

  /// Tags that left stock in the chosen period — sold or issued out.
  outTag('Out Tag', 'Tags sold'),

  /// Tags standing in stock right now, whenever they arrived.
  stock('Tag Stock', 'In stock');

  const TagStockSection(this.label, this.caption);

  final String label;

  /// Short description used on the empty state and the share text.
  final String caption;

  /// Whether this section is bounded by the chosen date range.
  ///
  /// Current stock is a position rather than a movement — it is whatever is
  /// on the shelf today, so a date range would be meaningless for it.
  bool get usesDateRange => this != TagStockSection.stock;
}

/// SQL fragment selecting the rows for [section].
///
/// Movement direction comes from ITM_SIGN rather than TR_TYPE, because a tag
/// can leave stock as a sale ('S') or as an issue ('O') and arrive as a
/// purchase ('P') or an opening entry ('I'); the sign is what every one of
/// those agrees on.
String tagSectionPredicate(TagStockSection section, String from, String to) {
  switch (section) {
    case TagStockSection.inTag:
      return "AND A.ITM_SIGN = '+' "
          "AND A.VCH_DATE >= '$from' AND A.VCH_DATE <= '$to' ";
    case TagStockSection.outTag:
      return "AND A.ITM_SIGN = '-' "
          "AND A.VCH_DATE >= '$from' AND A.VCH_DATE <= '$to' ";
    case TagStockSection.stock:
      // No date bound: handled by the HAVING clause, which nets the signs so
      // only tags still on hand survive.
      return '';
  }
}

/// The HAVING clause that keeps only tags still in stock.
///
/// Empty for the movement sections, which want the rows as they happened
/// rather than the net position.
String tagSectionHaving(TagStockSection section) => section ==
        TagStockSection.stock
    ? "HAVING SUM(CASE WHEN A.ITM_SIGN='+' THEN A.VCH_SRNO ELSE -A.VCH_SRNO END) > 0 "
    : '';

/// Image file name for a tag row, or empty when it has none.
///
/// Mirrors the rule the product grid and the tag estimate already use: a
/// design image when the piece has one, otherwise the tag's own photo. The
/// serial is parsed to an int because interpolating the raw numeric column
/// yields "1.0" and builds a file name the server does not have.
String tagImageFileName(dynamic row) {
  if (row is! Map) return '';
  final designId = '${row['DesignImgId'] ?? ''}'.trim();
  if (designId.isNotEmpty && designId != 'N') return '$designId.jpg';

  final tag = '${row['TagNo'] ?? ''}'.trim();
  if (tag.isEmpty || tag == 'N') return '';
  final srNo = num.tryParse('${row['VCH_SRNO'] ?? ''}')?.toInt();
  if (srNo == null) return '';
  return '${tag}_$srNo.jpg';
}
