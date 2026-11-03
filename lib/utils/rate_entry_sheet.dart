import 'package:DataCareUltra/utils/rate_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _brand = Color(0xFF006EB7);
const Color _textPrimary = Color(0xFF0F172A);
const Color _textSecondary = Color(0xFF64748B);
const Color _border = Color(0xFFCBD5E1);
const Color _pageBg = Color(0xFFF8FAFC);
const Color _hairline = Color(0xFFEEF2F6);
const Color _danger = Color(0xFFDC2626);
const Color _gold = Color(0xFFB7791F);
const Color _silver = Color(0xFF64748B);

/// Opens the rate entry form: the shop types the fine gold and fine silver
/// rates and watches every group's rate follow from its touch. Returns the
/// computed draft, or null if they backed out. Nothing is written here; the
/// caller saves.
Future<RateDraft?> showRateEntrySheet({
  required BuildContext context,
  required String title,
  required String dateLabel,
  required List<RateLine> lines,
  required double fineGold,
  required double fineSilver,
}) {
  return showModalBottomSheet<RateDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) => _RateEntrySheet(
      title: title,
      dateLabel: dateLabel,
      lines: lines,
      fineGold: fineGold,
      fineSilver: fineSilver,
    ),
  );
}

class _RateEntrySheet extends StatefulWidget {
  final String title;
  final String dateLabel;
  final List<RateLine> lines;
  final double fineGold;
  final double fineSilver;

  const _RateEntrySheet({
    required this.title,
    required this.dateLabel,
    required this.lines,
    required this.fineGold,
    required this.fineSilver,
  });

  @override
  State<_RateEntrySheet> createState() => _RateEntrySheetState();
}

class _RateEntrySheetState extends State<_RateEntrySheet> {
  late final TextEditingController _fineGold =
      TextEditingController(text: _show(widget.fineGold));
  late final TextEditingController _fineSilver =
      TextEditingController(text: _show(widget.fineSilver));
  String? _error;

  static String _show(double? v) => v == null || v == 0 ? '' : sqlNum(v);

  @override
  void dispose() {
    _fineGold.dispose();
    _fineSilver.dispose();
    super.dispose();
  }

  List<RateLine> get _computed => computeLines(
        lines: widget.lines,
        fineGold: parseRate(_fineGold.text) ?? 0,
        fineSilver: parseRate(_fineSilver.text) ?? 0,
      );

  void _save() {
    final gold = parseRate(_fineGold.text);
    final silver = parseRate(_fineSilver.text);
    if (_fineGold.text.trim().isNotEmpty && gold == null) {
      setState(() => _error = 'Fine gold rate is not a number.');
      return;
    }
    if (_fineSilver.text.trim().isNotEmpty && silver == null) {
      setState(() => _error = 'Fine silver rate is not a number.');
      return;
    }
    if ((gold ?? 0) <= 0 && (silver ?? 0) <= 0) {
      setState(() => _error = 'Enter the fine gold or fine silver rate.');
      return;
    }
    final lines = _computed;
    if (!lines.any((l) => l.hasRate)) {
      setState(() =>
          _error = 'No group has a touch set, so there is nothing to save.');
      return;
    }
    Navigator.pop(
      context,
      RateDraft(fineGold: gold ?? 0, fineSilver: silver ?? 0, lines: lines),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.92;
    final computed = _computed;
    final rated = computed.where((l) => l.hasRate).length;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                                'For ${widget.dateLabel} · each group follows its touch',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded,
                            color: _textSecondary, size: 21),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: _hairline),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    children: [
                      _fineCard(),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 8),
                        child: Text(
                            'GROUP RATES · $rated OF ${computed.length} WILL SAVE',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: _textSecondary)),
                      ),
                      for (var i = 0; i < computed.length; i++) ...[
                        _groupCard(widget.lines[i], computed[i]),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                Container(height: 1, color: _hairline),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        Text(_error!,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _danger)),
                        const SizedBox(height: 8),
                      ],
                      FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Save rates',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fineCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: _brand.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brand.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FINE METAL RATES',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: _brand)),
          const SizedBox(height: 2),
          Text('With tax, as quoted; every group rate below is per 10 g',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _field('Fine gold / 10 g', _fineGold)),
              const SizedBox(width: 10),
              Expanded(child: _field('Fine silver / kg', _fineSilver)),
            ],
          ),
        ],
      ),
    );
  }

  /// One group: what it is on now, and what it becomes for the typed fine
  /// rates. [stored] is the line as loaded, [now] the computed one.
  Widget _groupCard(RateLine stored, RateLine now) {
    final skip = now.skipReason;
    final waiting = skip == null && !now.hasRate; // fine rate not typed yet
    final muted = skip != null;

    final details = <String>[
      if (now.hasTouch) 'Touch ${sqlNum(now.touch!)}%',
      if ((now.taxPrc ?? 0) > 0) 'Tax ${sqlNum(now.taxPrc!)}%',
      if (stored.hasRate)
        'Now ${sqlNum((stored.taxRate ?? 0) > 0 ? stored.taxRate! : stored.rate!)}',
    ];

    return Opacity(
      opacity: muted ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
        decoration: BoxDecoration(
          color: muted ? _pageBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                            stored.name.isEmpty ? stored.code : stored.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      _metalChip(now.metal),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      skip ?? (details.isEmpty ? stored.code : details.join(' · ')),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: muted ? _danger : _textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    now.hasRate
                        ? sqlNum(now.taxRate!)
                        : (waiting ? '—' : 'skip'),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: now.hasRate ? _brand : _textSecondary)),
                if (now.hasRate && (now.taxPrc ?? 0) > 0)
                  Text('without tax ${sqlNum(now.rate!)}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metalChip(Metal metal) {
    final (label, color) = switch (metal) {
      Metal.gold => ('GOLD', _gold),
      Metal.silver => ('SILVER', _silver),
      Metal.other => ('OTHER', _textSecondary),
      Metal.unknown => ('?', _danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: color)),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() => _error = null),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      textInputAction: TextInputAction.next,
      cursorColor: _brand,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w700, color: _brand),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _textSecondary),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12.5, fontWeight: FontWeight.w700, color: _brand),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brand, width: 1.5),
        ),
      ),
    );
  }
}
