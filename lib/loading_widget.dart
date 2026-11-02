import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'provider/loading_provider.dart';

/// Global loading overlay. Mounted once around the whole app in
/// [MaterialApp.builder], so it sits above every route.
///
/// While [LoadingProvider.isLoading] is true the overlay fades in, dims the
/// app behind a scrim and absorbs all touch input so a second tap cannot fire
/// a duplicate request.
class Loading extends StatelessWidget {
  final Widget? child;

  /// Label shown under the spinner. Pass an empty string to hide it.
  final String message;

  const Loading({super.key, this.child, this.message = "Please wait"});

  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingProvider>(
      builder: (context, data, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // `child` is nullable on MaterialApp.builder, so never force-unwrap.
            child ?? const SizedBox.shrink(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: data.isLoading
                  ? _overlay(context)
                  : const SizedBox.shrink(key: ValueKey('idle')),
            ),
          ],
        );
      },
    );
  }

  Widget _overlay(BuildContext context) {
    return AbsorbPointer(
      key: const ValueKey('loading'),
      child: Semantics(
        label: 'Loading',
        liveRegion: true,
        child: Container(
          // Flat scrim rather than a BackdropFilter: a full-screen blur on
          // every request janks on low-end devices.
          color: Colors.black.withValues(alpha: 0.32),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: message.isEmpty ? 22 : 26,
                vertical: 22,
              ),
              constraints: const BoxConstraints(minWidth: 108, maxWidth: 260),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SpinKitFadingCube(color: _brand, size: 32),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
