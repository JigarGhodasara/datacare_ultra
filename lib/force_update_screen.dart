import 'dart:io';

import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/app_version.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Blocking screen shown when the installed build is older than the minimum
/// version the backend requires.
///
/// It is deliberately a full route rather than a dialog: a dialog can be
/// dismissed by a tap outside or a back gesture, which would let the user
/// straight into an unsupported build.
class ForceUpdateScreen extends StatefulWidget {
  /// Version the user currently has installed, e.g. "1.0.17".
  final String currentVersion;

  /// Version they need to move to.
  final String requiredVersion;

  /// Optional note from the backend ("adds the new stock report", etc.).
  final String? releaseNote;

  /// When false the user may continue on the old build — used for a
  /// recommended-but-not-mandatory update.
  final bool mandatory;

  /// Canonical store listing resolved by the version lookup, when available.
  final String? storeUrl;

  const ForceUpdateScreen({
    super.key,
    required this.currentVersion,
    required this.requiredVersion,
    this.releaseNote,
    this.mandatory = true,
    this.storeUrl,
  });

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _hairline = Color(0xFFEEF2F6);

  bool _opening = false;

  String get _storeName => Platform.isIOS ? "App Store" : "Play Store";

  Future<void> _update() async {
    if (_opening) return;
    setState(() => _opening = true);
    final opened = await openStoreListing(storeUrl: widget.storeUrl);
    if (!mounted) return;
    setState(() => _opening = false);
    if (!opened) {
      showAppToast(
          context,
          "Could not open the $_storeName. Please open it "
          "manually and search for DataCare Ultra.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // A mandatory update must survive the Android back button and the iOS
      // swipe-back gesture, otherwise the gate is trivially bypassed.
      canPop: !widget.mandatory,
      child: Scaffold(
        backgroundColor: _pageBg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                // Scrollable so the content still fits on short screens and
                // in landscape, rather than overflowing.
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(),
                          _artwork(),
                          const SizedBox(height: 32),
                          _headline(),
                          const SizedBox(height: 12),
                          _body(),
                          const SizedBox(height: 24),
                          _versionCard(),
                          if (widget.releaseNote != null &&
                              widget.releaseNote!.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _releaseNote(),
                          ],
                          const Spacer(),
                          const SizedBox(height: 24),
                          _updateButton(),
                          if (!widget.mandatory) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                "Not now",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _artwork() {
    return Center(
      child: Container(
        height: 132,
        width: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _brand.withValues(alpha: 0.14),
              _brand.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Center(
          child: Container(
            height: 88,
            width: 88,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _hairline),
              boxShadow: [
                BoxShadow(
                  color: _textPrimary.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Image.asset(AppImage.appLogo, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _headline() {
    return Text(
      widget.mandatory ? "Update required" : "Update available",
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: _textPrimary,
      ),
    );
  }

  Widget _body() {
    return Text(
      widget.mandatory
          ? "A newer version of DataCare Ultra is required to continue. "
              "Please update from the $_storeName to keep using the app."
          : "A newer version of DataCare Ultra is available on the $_storeName "
              "with the latest improvements.",
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14.5,
        height: 1.55,
        fontWeight: FontWeight.w500,
        color: _textSecondary,
      ),
    );
  }

  Widget _versionCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _hairline),
        boxShadow: [
          BoxShadow(
            color: _textPrimary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _versionCell("Installed", widget.currentVersion,
                color: _textSecondary),
          ),
          const Icon(Icons.arrow_forward_rounded, size: 18, color: _brand),
          Expanded(
            child:
                _versionCell("Required", widget.requiredVersion, color: _brand),
          ),
        ],
      ),
    );
  }

  Widget _versionCell(String label, String value, {required Color color}) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value.trim().isEmpty ? "—" : value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _releaseNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "WHAT'S NEW",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: _brand,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.releaseNote!.trim(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _updateButton() {
    return SizedBox(
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _brand,
          disabledBackgroundColor: _brand.withValues(alpha: 0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: _opening ? null : _update,
        child: _opening
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.system_update_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "Update on $_storeName",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Shows the gate as a route that cannot be dismissed when [mandatory].
Future<void> showForceUpdateScreen(
  BuildContext context, {
  required String currentVersion,
  required String requiredVersion,
  String? releaseNote,
  bool mandatory = true,
  String? storeUrl,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => ForceUpdateScreen(
        currentVersion: currentVersion,
        requiredVersion: requiredVersion,
        releaseNote: releaseNote,
        mandatory: mandatory,
        storeUrl: storeUrl,
      ),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
  );
}
