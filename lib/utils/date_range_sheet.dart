import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Clamps [day] to a month that may not have it — 31 January to February
/// becomes 28 or 29 rather than silently rolling into March.
DateTime safeDate(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}

/// Named ranges, so the common choices need no date picking at all.
enum RangePreset {
  today('Today'),
  last7('Last 7 days'),
  last30('Last 30 days'),
  thisMonth('This month'),
  lastMonth('Last month'),
  thisYear('This year');

  const RangePreset(this.label);
  final String label;

  DateTimeRange resolve(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case RangePreset.today:
        return DateTimeRange(start: today, end: today);
      case RangePreset.last7:
        return DateTimeRange(
            start: today.subtract(const Duration(days: 6)), end: today);
      case RangePreset.last30:
        return DateTimeRange(
            start: today.subtract(const Duration(days: 29)), end: today);
      case RangePreset.thisMonth:
        return DateTimeRange(
            start: DateTime(today.year, today.month, 1), end: today);
      case RangePreset.lastMonth:
        final firstOfThis = DateTime(today.year, today.month, 1);
        final lastMonthEnd = firstOfThis.subtract(const Duration(days: 1));
        return DateTimeRange(
            start: DateTime(lastMonthEnd.year, lastMonthEnd.month, 1),
            end: lastMonthEnd);
      case RangePreset.thisYear:
        return DateTimeRange(start: DateTime(today.year, 1, 1), end: today);
    }
  }
}

/// Picks a date range using day / month / year dropdowns.
///
/// Replaces `showDateRangePicker`, whose calendar meant scrolling month by
/// month to reach anything far from today — painful for a report covering last
/// year. Here each part of the date is chosen directly, and the common ranges
/// are one tap via the presets.
///
/// Returns null if dismissed.
Future<DateTimeRange?> showDateRangeSheet(
  BuildContext context, {
  required DateTime from,
  required DateTime to,
  DateTime? firstYear,
  DateTime? lastYear,
}) {
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DateRangeSheet(
      from: from,
      to: to,
      firstYear: firstYear?.year ?? DateTime.now().year - 10,
      lastYear: lastYear?.year ?? DateTime.now().year + 1,
    ),
  );
}

class _DateRangeSheet extends StatefulWidget {
  final DateTime from;
  final DateTime to;
  final int firstYear;
  final int lastYear;

  const _DateRangeSheet({
    required this.from,
    required this.to,
    required this.firstYear,
    required this.lastYear,
  });

  @override
  State<_DateRangeSheet> createState() => _DateRangeSheetState();
}

class _DateRangeSheetState extends State<_DateRangeSheet> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _hairline = Color(0xFFEEF2F6);
  static const Color _danger = Color(0xFFDC2626);

  late DateTime _from = widget.from;
  late DateTime _to = widget.to;

  bool get _invalid => _from.isAfter(_to);

  void _applyPreset(RangePreset preset) {
    final range = preset.resolve(DateTime.now());
    setState(() {
      _from = range.start;
      _to = range.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Select date range',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in RangePreset.values) _presetChip(preset),
                ],
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: _hairline),
              const SizedBox(height: 16),
              _dateRow('From', _from, (d) => setState(() => _from = d)),
              const SizedBox(height: 14),
              _dateRow('To', _to, (d) => setState(() => _to = d)),
              const SizedBox(height: 14),
              if (_invalid)
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 15, color: _danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'The "from" date is after the "to" date.',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _danger),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '${DateFormat('dd MMM yyyy').format(_from)}  –  '
                  '${DateFormat('dd MMM yyyy').format(_to)}'
                  '   (${_to.difference(_from).inDays + 1} days)',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textSecondary,
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      // Blocked rather than silently swapped: a reversed range
                      // is usually a mis-tap, and quietly "fixing" it would
                      // show a report for dates nobody asked for.
                      onPressed: _invalid
                          ? null
                          : () => Navigator.pop(
                              context, DateTimeRange(start: _from, end: _to)),
                      style: FilledButton.styleFrom(
                        backgroundColor: _brand,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                      ),
                      child: Text('Apply',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(RangePreset preset) {
    final range = preset.resolve(DateTime.now());
    final selected = _sameDay(range.start, _from) && _sameDay(range.end, _to);
    return GestureDetector(
      onTap: () => _applyPreset(preset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _brand : _hairline,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(preset.label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _textSecondary)),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _dateRow(String label, DateTime value, ValueChanged<DateTime> onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _textSecondary)),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _dropdown<int>(
                value: value.day,
                // Only the days this month actually has, so 31 February can
                // never be chosen in the first place.
                items: [
                  for (var d = 1;
                      d <= DateTime(value.year, value.month + 1, 0).day;
                      d++)
                    DropdownMenuItem(value: d, child: Text('$d'))
                ],
                onChanged: (d) =>
                    onPick(safeDate(value.year, value.month, d ?? value.day)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _dropdown<int>(
                value: value.month,
                items: [
                  for (var m = 1; m <= 12; m++)
                    DropdownMenuItem(
                        value: m,
                        child:
                            Text(DateFormat('MMM').format(DateTime(2000, m))))
                ],
                onChanged: (m) =>
                    onPick(safeDate(value.year, m ?? value.month, value.day)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _dropdown<int>(
                value: value.year.clamp(widget.firstYear, widget.lastYear),
                items: [
                  for (var y = widget.lastYear; y >= widget.firstYear; y--)
                    DropdownMenuItem(value: y, child: Text('$y'))
                ],
                onChanged: (y) =>
                    onPick(safeDate(y ?? value.year, value.month, value.day)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          // Capped so the list opens as a short menu instead of a full-height
          // sheet that has to be scrolled.
          menuMaxHeight: 280,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.expand_more_rounded,
              size: 18, color: _textSecondary),
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5, fontWeight: FontWeight.w700, color: _textPrimary),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
