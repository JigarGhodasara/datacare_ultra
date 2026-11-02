import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Voucher number badge used on ledger transaction cards.
///
/// Voucher numbers vary a lot in length between books — some are a few digits,
/// others carry a long alphabetic prefix — so this is built to degrade
/// gracefully: it hugs a short number, and a long one ellipsises rather than
/// pushing the rest of the card header out of shape. Long-press shows the
/// value in full.
class VoucherChip extends StatelessWidget {
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _pageBg = Color(0xFFF8FAFC);

  /// The voucher number, already trimmed by [numberOf].
  final String vchNo;

  const VoucherChip({super.key, required this.vchNo});

  /// Reads VCH_NO out of a result row.
  ///
  /// VCH_NO is a padded CHAR column, so it arrives with trailing spaces.
  /// Trimming means the chip is not sized for whitespace, and an all-blank
  /// value comes back empty so the caller can drop the chip entirely instead
  /// of rendering an empty box.
  static String numberOf(dynamic row) => '${row['VCH_NO'] ?? ''}'.trim();

  @override
  Widget build(BuildContext context) {
    if (vchNo.isEmpty) return const SizedBox.shrink();
    return Tooltip(
      message: vchNo,
      triggerMode: TooltipTriggerMode.longPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: _pageBg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _border.withValues(alpha: 0.8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 13,
              color: _textSecondary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 5),
            // Flexible, not Expanded: the chip stays tight around a short
            // number and only gives way once the text runs out of room.
            Flexible(
              child: Text(
                vchNo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: _textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
