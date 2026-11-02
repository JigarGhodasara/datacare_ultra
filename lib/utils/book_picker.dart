import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _brand = Color(0xFF006EB7);
const Color _textPrimary = Color(0xFF0F172A);
const Color _textSecondary = Color(0xFF64748B);
const Color _border = Color(0xFFCBD5E1);
const Color _pageBg = Color(0xFFF8FAFC);

/// A single selectable option: [value] is what the caller stores, [label] is
/// what the user reads.
class PickerOption {
  final String value;
  final String label;

  const PickerOption(this.value, this.label);
}

/// Drops options whose [PickerOption.value] has already been seen, keeping
/// the first. A dropdown with two items of the same value cannot tell which
/// one is selected, so lists from the database are passed through this first.
List<PickerOption> distinctOptions(Iterable<PickerOption> options) {
  final seen = <String>{};
  return [
    for (final o in options)
      if (seen.add(o.value)) o,
  ];
}

/// The value a picker should hold once its options are (re)loaded: [current]
/// if it is still offered, otherwise the first option, or '' when there are
/// none. A field never holds a value that is not in its list.
String pickSelected(List<PickerOption> options, String current) {
  if (options.isEmpty) return '';
  return options.any((o) => o.value == current) ? current : options.first.value;
}

/// Full-height modal list used in place of an inline dropdown overlay.
///
/// A `DropdownButton2` menu anchors to its button, so near the bottom of the
/// screen or inside a bottom sheet it gets clipped by the screen edge and long
/// lists become unreachable. This sheet always owns its own scroll area, so
/// every option is reachable on any screen size.
///
/// Returns the chosen value, or null if dismissed.
Future<String?> showOptionPicker({
  required BuildContext context,
  required List<PickerOption> options,
  required String selected,
  required String title,
  String searchHint = "Search",
  String emptyText = "Nothing found",
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) => _BookPickerSheet(
      options: options,
      selected: selected,
      title: title,
      searchHint: searchHint,
      emptyText: emptyText,
    ),
  );
}

/// [showOptionPicker] with the wording the report screens use for books.
Future<String?> showBookPicker({
  required BuildContext context,
  required List<PickerOption> options,
  required String selected,
  String title = "Select book",
}) {
  return showOptionPicker(
    context: context,
    options: options,
    selected: selected,
    title: title,
    searchHint: "Search book",
    emptyText: "No book found",
  );
}

/// Lists at least this long get a search box in the picker.
const int kPickerSearchThreshold = 8;

class _BookPickerSheet extends StatefulWidget {
  final List<PickerOption> options;
  final String selected;
  final String title;
  final String searchHint;
  final String emptyText;

  const _BookPickerSheet({
    required this.options,
    required this.selected,
    required this.title,
    required this.searchHint,
    required this.emptyText,
  });

  @override
  State<_BookPickerSheet> createState() => _BookPickerSheetState();
}

class _BookPickerSheetState extends State<_BookPickerSheet> {
  final TextEditingController _search = TextEditingController();
  late List<PickerOption> _visible = widget.options;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _filter(String term) {
    final q = term.trim().toLowerCase();
    setState(() {
      _visible = q.isEmpty
          ? widget.options
          : widget.options
              .where((o) => o.label.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Cap at 78% of the screen so the sheet never runs past the top, and let
    // the keyboard push it up when the search field is focused.
    final maxHeight = media.size.height * 0.78;

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
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: [
                      Text(widget.title,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded,
                            color: _textSecondary, size: 21),
                      ),
                    ],
                  ),
                ),
                if (widget.options.length >= kPickerSearchThreshold)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _search,
                      onChanged: _filter,
                      cursorColor: _brand,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: _brand, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _brand, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                Container(height: 1, color: const Color(0xFFEEF2F6)),
                Flexible(
                  child: _visible.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(widget.emptyText,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary)),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _visible.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, i) {
                            final option = _visible[i];
                            final isSelected = option.value == widget.selected;
                            return InkWell(
                              onTap: () => Navigator.pop(context, option.value),
                              child: Container(
                                color: isSelected
                                    ? _brand.withValues(alpha: 0.05)
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 15),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option.label,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? _brand
                                              : _textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_rounded,
                                          color: _brand, size: 20),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The tappable field that opens the picker. Mirrors the date-box styling.
Widget bookPickerField({
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      height: 52,
      padding: const EdgeInsets.only(left: 16, right: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, _pageBg],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border.withValues(alpha: 0.85)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: _brand, size: 22),
        ],
      ),
    ),
  );
}
