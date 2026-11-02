import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Plain-language explanation of one list on the Insights tab.
///
/// The figures themselves were never the problem — "Trending items, +3.500 gm"
/// is accurate and still tells a shopkeeper nothing about where the number came
/// from or why their best seller is missing from it. Each list therefore
/// carries a one-line [caption] on the card and a fuller explanation behind an
/// info button, written in the words a counter uses rather than the words the
/// query uses.
///
/// The copy lives outside the screen so the wording can be checked, and read,
/// without wading through layout code.
@immutable
class InsightHelp {
  /// One line, shown under the card title. Must stand alone: most users will
  /// never open the full explanation.
  final String caption;

  /// What the list answers.
  final String what;

  /// Where the numbers come from, in concrete terms — real dates rather than
  /// "the previous period".
  final String how;

  /// A caveat worth stating, where the honest reading of the list is not the
  /// obvious one. Null when there is nothing to warn about.
  final String? note;

  const InsightHelp({
    required this.caption,
    required this.what,
    required this.how,
    this.note,
  });
}

String _day(DateTime d) => DateFormat("dd MMM yyyy").format(d);

/// `01 – 30 Nov 2026`, collapsing the parts both ends share.
String rangeLabel(DateTime from, DateTime to) {
  // A one-day range is a date, not a span: "07 – 07 Nov" reads as a mistake.
  if (from.year == to.year && from.month == to.month && from.day == to.day) {
    return _day(to);
  }
  if (from.year == to.year && from.month == to.month) {
    return "${DateFormat("dd").format(from)} – ${DateFormat("dd MMM yyyy").format(to)}";
  }
  if (from.year == to.year) {
    return "${DateFormat("dd MMM").format(from)} – ${DateFormat("dd MMM yyyy").format(to)}";
  }
  return "${_day(from)} – ${_day(to)}";
}

InsightHelp topSellingHelp(DateTime from, DateTime to) => InsightHelp(
      caption: "Most sold, heaviest first",
      what: "The items that moved the most out of your shop in the selected "
          "dates.",
      how: "Every sale line between ${rangeLabel(from, to)} is added up "
          "against its item name. The big figure is the total weight sold; "
          "the line under the name is how many pieces that was.",
      note: "An item sold without a weight entered is still listed, with its "
          "piece count in place of the weight.",
    );

InsightHelp trendingHelp(
  DateTime from,
  DateTime to,
  DateTime prevFrom,
  DateTime prevTo,
) =>
    InsightHelp(
      caption: "Selling more than they were before",
      what: "Items that are picking up — selling more now than they were "
          "just before.",
      how: "Your dates (${rangeLabel(from, to)}) are compared with the same "
          "number of days immediately before them "
          "(${rangeLabel(prevFrom, prevTo)}). Only items that went up are "
          "listed, biggest rise first, and the big figure is the extra "
          "weight sold.",
      note: "This is about change, not size. Your biggest seller can be "
          "missing from here — that only means it sold about the same as "
          "before, not that it is doing badly.",
    );

InsightHelp bestCustomersHelp(DateTime from, DateTime to) => InsightHelp(
      caption: "Highest billing in these dates",
      what: "The customers who spent the most with you in the selected "
          "dates.",
      how: "Every bill between ${rangeLabel(from, to)} is added up against "
          "its customer. The big figure is the total amount billed; the line "
          "under the name is how many bills that was, and their mobile "
          "number.",
      note: "This counts what was billed, not what was collected — a "
          "customer high on this list may still owe you money.",
    );

InsightHelp outstandingHelp(DateTime asOn) => InsightHelp(
      caption: "Still to be received, largest first",
      what: "Parties who owe you money, with the biggest balance at the top.",
      how: "Taken from the outstanding report as on ${_day(asOn)} — the "
          "closing date of your selected range. The big figure is the "
          "balance still to come in.",
      note: "This is the position on that one date, not something that "
          "happened during the range, so it does not change when you shorten "
          "the dates — only when you move the closing date.",
    );
