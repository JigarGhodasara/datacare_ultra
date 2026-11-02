import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/tagEstimate_screen.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Symbologies the tag scanner reads: QR plus the 1D barcodes jewellery tag
/// printers normally use, and Data Matrix for the tiny 2D labels on small
/// tags. Every entry here decodes on both Android (ZXing) and iOS
/// (AVFoundation); Codabar, MaxiCode and RSS are left out because iOS cannot
/// read them and the plugin would silently treat them as QR.
const List<BarcodeFormat> kTagScanFormats = [
  BarcodeFormat.qrcode,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.itf,
  BarcodeFormat.dataMatrix,
];

class QRViewExample extends StatefulWidget {
  final bool isFromTagScreen;
  const QRViewExample({Key? key, required this.isFromTagScreen})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  bool _isHandlingScan = false;
  bool _flashOn = false;
  bool _permissionDenied = false;

  // In order to get hot reload to work we need to pause the camera if the
  // platform is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Pause the camera the moment a pop starts (system back gesture / button)
      // so the live stream stops before the route teardown, which otherwise
      // blocks the UI thread and freezes the screen on close.
      onPopInvokedWithResult: (didPop, result) {
        controller?.pauseCamera();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildQrView(context),
            _buildOverlayUi(context),
            if (_permissionDenied) _buildPermissionDenied(context),
          ],
        ),
      ),
    );
  }

  double _scanArea(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // A snug frame improves focus/accuracy: use ~70% of the shorter side,
    // clamped so it stays reasonable on very small or very large screens.
    final shorterSide = size.width < size.height ? size.width : size.height;
    return (shorterSide * 0.7).clamp(180.0, 320.0);
  }

  /// Frame width: a quarter wider than it is tall so a printed 1D barcode
  /// sits comfortably inside, but never closer than 24dp to either edge.
  double _scanWidth(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width - 48;
    final wanted = _scanArea(context) * 1.25;
    return wanted < maxWidth ? wanted : maxWidth;
  }

  Widget _buildQrView(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      formatsAllowed: kTagScanFormats,
      overlay: QrScannerOverlayShape(
        borderColor: AppColor.blueColor,
        borderRadius: 16,
        borderLength: 32,
        borderWidth: 8,
        // Wider than tall so a printed 1D barcode sits comfortably inside
        // the frame; a QR still fits in the middle.
        cutOutWidth: _scanWidth(context),
        cutOutHeight: _scanArea(context),
        overlayColor: Colors.black.withValues(alpha: 0.6),
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  Widget _buildOverlayUi(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          const Spacer(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Align the QR code or barcode within the frame to scan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildControls(context),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 22),
            onPressed: _closeScanner,
          ),
          const SizedBox(width: 4),
          const Text(
            'Scan Tag',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(
          icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          label: _flashOn ? 'Flash On' : 'Flash Off',
          active: _flashOn,
          onTap: _toggleFlash,
        ),
        const SizedBox(width: 40),
        _circleButton(
          icon: Icons.flip_camera_ios_rounded,
          label: 'Flip',
          active: false,
          onTap: _flipCamera,
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColor.blueColor
                  : Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPermissionDenied(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_rounded,
              color: Colors.white54, size: 64),
          const SizedBox(height: 20),
          const Text(
            'Camera permission denied',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please allow camera access in Settings to scan tags.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.blueColor,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              setState(() => _permissionDenied = false);
              await controller?.resumeCamera();
            },
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _closeScanner() async {
    // Stop the live camera stream before popping so the heavy platform-side
    // teardown doesn't run during the route transition and freeze the UI.
    await controller?.pauseCamera();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _toggleFlash() async {
    try {
      await controller?.toggleFlash();
      final status = await controller?.getFlashStatus();
      if (!mounted) return;
      setState(() => _flashOn = status ?? !_flashOn);
    } catch (e, s) {
      log('toggleFlash failed', error: e, stackTrace: s);
    }
  }

  Future<void> _flipCamera() async {
    try {
      await controller?.flipCamera();
      // Flash state resets when switching cameras.
      final status = await controller?.getFlashStatus();
      if (!mounted) return;
      setState(() => _flashOn = status ?? false);
    } catch (e, s) {
      log('flipCamera failed', error: e, stackTrace: s);
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      final code = scanData.code?.trim() ?? "";
      // Guard against the stream firing multiple times before the camera
      // actually pauses, which previously caused duplicate navigation.
      if (_isHandlingScan || code.isEmpty) return;
      _isHandlingScan = true;
      controller.pauseCamera();

      if (widget.isFromTagScreen) {
        Navigator.pop(context, [code]);
      } else {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TagestimateScreen(tagNo: code),
          ),
        );
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!mounted) return;
    setState(() => _permissionDenied = !p);
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required to scan')),
      );
    }
  }

  @override
  void dispose() {
    controller?.pauseCamera();
    controller?.dispose();
    super.dispose();
  }
}
