import 'dart:typed_data';

import 'package:DataCareUltra/utils/image_effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shown straight after a tag photo is picked, so the touch-ups can be judged
/// on the actual photo before anything is uploaded.
///
/// Pops the bytes to save, or null if the user backs out.
class PhotoReviewScreen extends StatefulWidget {
  /// The picked photo, already turned upright.
  final Uint8List original;

  /// How the touch-ups are applied. Injectable so widget tests can drive the
  /// screen without spawning the real processing isolate, which never settles
  /// under `pumpAndSettle`.
  final Future<Uint8List> Function(Uint8List, PhotoEffects) applyEffects;

  const PhotoReviewScreen({
    super.key,
    required this.original,
    this.applyEffects = ImageEffects.apply,
  });

  @override
  State<PhotoReviewScreen> createState() => _PhotoReviewScreenState();
}

class _PhotoReviewScreenState extends State<PhotoReviewScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _pageBg = Color(0xFFF4F6FA);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  PhotoEffects _effects = const PhotoEffects();
  late Uint8List _preview = widget.original;
  bool _working = false;

  /// Guards against an earlier, slower render overwriting a later one when the
  /// user flips two switches quickly.
  int _renderToken = 0;

  Future<void> _render(PhotoEffects next) async {
    final token = ++_renderToken;
    setState(() {
      _effects = next;
      _working = true;
    });
    // Always re-derive from the original: applying an effect to an already
    // processed preview would stack the adjustments every time a switch moved.
    final out = await widget.applyEffects(widget.original, next);
    if (!mounted || token != _renderToken) return;
    setState(() {
      _preview = out;
      _working = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: _textPrimary,
          centerTitle: true,
          title: Text(
            'Review Photo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: _brand,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: _brand,
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: _border),
          ),
        ),
        body: Column(
          children: [
            Expanded(child: _previewPane()),
            _optionsPane(),
          ],
        ),
      ),
    );
  }

  Widget _previewPane() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // gaplessPlayback keeps the old frame on screen while the new one
          // decodes, so toggling a switch does not make the photo flicker.
          Image.memory(
            _preview,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
          if (_working)
            Container(
              color: Colors.white.withValues(alpha: 0.55),
              child: const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: _brand,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _optionsPane() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _optionTile(
              icon: Icons.auto_fix_high_rounded,
              title: 'Enhance photo',
              subtitle: 'Brighten, sharpen and lift dull colours',
              value: _effects.enhance,
              onChanged: (v) => _render(_effects.copyWith(enhance: v)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _working ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondary,
                      side: BorderSide(color: _border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Retake',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    // Disabled mid-render so the photo that gets saved is
                    // always the one being looked at.
                    onPressed: _working
                        ? null
                        : () => Navigator.pop(context, _preview),
                    style: FilledButton.styleFrom(
                      backgroundColor: _brand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Save Photo',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: value ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon,
              size: 19,
              color: value ? _brand : _textSecondary.withValues(alpha: 0.8)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeTrackColor: _brand,
          // Locked while a render is in flight: a second toggle mid-render
          // would leave the switches and the picture disagreeing.
          onChanged: _working ? null : onChanged,
        ),
      ],
    );
  }
}
