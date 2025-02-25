// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
//
// class QrcodeScreen extends StatefulWidget {
//   const QrcodeScreen({Key? key}) : super(key: key);
//
//   @override
//   State<QrcodeScreen> createState() => _QrcodeScreenState();
// }
//
// class _QrcodeScreenState extends State<QrcodeScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: QRCodeDartScanView(
//         // scanInvertedQRCode: true, // enable scan invert qr code ( default = false)
//
//         typeScan: TypeScan.live, // if TypeScan.takePicture will try decode when click to take a picture(default TypeScan.live)
//         // intervalScan: const Duration(seconds:1)
//         // onResultInterceptor: (old,new){
//         //  do any rule to controll onCapture.
//         // }
//         // takePictureButtonBuilder: (context,controller,isLoading){ // if typeScan == TypeScan.takePicture you can customize the button.
//         //    if(loading) return CircularProgressIndicator();
//         //    return ElevatedButton(
//         //       onPressed:controller.takePictureAndDecode,
//         //       child:Text('Take a picture'),
//         //    );
//         // }
//         // resolutionPreset: = QrCodeDartScanResolutionPreset.high,
//         formats: [ // You can restrict specific formats.
//          BarcodeFormat.qrCode,
//          // BarcodeFormat.aztec,
//          // BarcodeFormat.dataMatrix,
//          // BarcodeFormat.pdf417,
//          // BarcodeFormat.code39,
//          // BarcodeFormat.code93,
//          // BarcodeFormat.code128,
//          // BarcodeFormat.ean8,
//          // BarcodeFormat.ean13,
//         ],
//         onCapture: (Result result) {
//           print("Result $result");
//           // do anything with result
//           // result.text
//           // result.rawBytes
//           // result.resultPoints
//           // result.format
//           // result.numBits
//           // result.resultMetadata
//           // result.time
//         },
//       ),
//     );
//   }
// }
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/tagEstimate_screen.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRViewExample extends StatefulWidget {
  bool isFromTagScreen;
  QRViewExample({Key? key,required this.isFromTagScreen}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildQrView(context)
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: AppColor.blueColor,
          borderRadius: 10,
          // borderLength: 30,
          borderWidth: 10,
          // cutOutSize: scanArea
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      print("Scanned DATA ${scanData.code}");

      if(scanData.code != ""){
        controller.pauseCamera();
        if(widget.isFromTagScreen){
          print("22222");
          Navigator.pop(context,["${scanData.code}"]);
        }else{
          print("111111");
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context)=> TagestimateScreen(tagNo: scanData.code,)));
        }
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}