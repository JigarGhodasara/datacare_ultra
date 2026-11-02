import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Rewrites a picked photo so it is stored the right way up.
///
/// A camera does not physically rotate its sensor when the phone is turned; it
/// writes the photo in the sensor's own orientation and records how it should
/// be turned in an EXIF `Orientation` tag. Anything that reads that tag shows
/// the photo correctly, and anything that ignores it shows the photo rotated.
///
/// Flutter's own `Image` widget ignores the tag, and so does the desktop ERP
/// software these photos end up in — so the rotation has to be baked into the
/// pixels here, before the image is stored, rather than relied on downstream.
/// `FlutterImageCompress` used to do this as an undocumented side effect; when
/// it was removed from the upload path the rotation came back.
class ImagePrepare {
  const ImagePrepare._();

  /// Returns [bytes] rotated upright, or [bytes] unchanged when there is
  /// nothing to correct.
  ///
  /// Fails open: if the image cannot be decoded, the original bytes are
  /// returned rather than the upload being blocked. A photo the wrong way up
  /// is a far smaller problem than a photo that cannot be saved at all.
  static Future<Uint8List> uprightOrientation(Uint8List bytes) async {
    if (bytes.isEmpty) return bytes;
    try {
      // Decoding is pure Dart and costs real time on a large photo, so it runs
      // off the UI isolate to avoid a visible freeze after the shutter.
      final rotated = await compute(_bakeSync, bytes);
      return rotated ?? bytes;
    } catch (_) {
      return bytes;
    }
  }

  /// The EXIF `Orientation` of a JPEG, or null when there isn't one.
  ///
  /// Exposed for testing. Reads the raw bytes rather than going through
  /// [img.decodeImage], which is no use here: the package's JPEG decoder
  /// *applies* the orientation while decoding and clears the tag, so by the
  /// time you hold a decoded image the original value is gone.
  @visibleForTesting
  static int? readJpegOrientation(Uint8List b) {
    if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) return null;
    var i = 2;
    while (i + 3 < b.length) {
      if (b[i] != 0xFF) return null; // lost marker alignment
      final marker = b[i + 1];
      // Padding, and standalone markers that carry no length field.
      if (marker == 0xFF ||
          marker == 0x01 ||
          (marker >= 0xD0 && marker <= 0xD8)) {
        i += marker == 0xFF ? 1 : 2;
        continue;
      }
      // Start of scan / end of image: all metadata is behind us.
      if (marker == 0xDA || marker == 0xD9) return null;
      final len = (b[i + 2] << 8) | b[i + 3];
      if (len < 2 || i + 2 + len > b.length) return null;
      if (marker == 0xE1) {
        final found = _orientationFromApp1(b, i + 4, i + 2 + len);
        if (found != null) return found;
      }
      i += 2 + len;
    }
    return null;
  }
}

/// Reads the Orientation tag out of one APP1 segment spanning [start], [end).
int? _orientationFromApp1(Uint8List b, int start, int end) {
  // "Exif\0\0"
  const signature = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
  if (end - start < signature.length + 8) return null;
  for (var k = 0; k < signature.length; k++) {
    if (b[start + k] != signature[k]) return null;
  }

  final tiff = start + signature.length;
  final bool little;
  if (b[tiff] == 0x49 && b[tiff + 1] == 0x49) {
    little = true;
  } else if (b[tiff] == 0x4D && b[tiff + 1] == 0x4D) {
    little = false;
  } else {
    return null;
  }

  int u16(int at) => at + 1 >= end
      ? -1
      : (little ? b[at] | (b[at + 1] << 8) : (b[at] << 8) | b[at + 1]);
  int u32(int at) => at + 3 >= end
      ? -1
      : (little
          ? b[at] | (b[at + 1] << 8) | (b[at + 2] << 16) | (b[at + 3] << 24)
          : (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3]);

  if (u16(tiff + 2) != 42) return null; // TIFF magic

  final ifdOffset = u32(tiff + 4);
  if (ifdOffset < 8) return null;
  final ifd = tiff + ifdOffset;
  final count = u16(ifd);
  if (count <= 0) return null;

  for (var k = 0; k < count; k++) {
    final entry = ifd + 2 + (k * 12);
    if (entry + 12 > end) return null;
    if (u16(entry) == 0x0112) {
      // Orientation. Type is SHORT, so the value sits in the first two bytes
      // of the entry's 4-byte value field.
      final value = u16(entry + 8);
      return (value >= 1 && value <= 8) ? value : null;
    }
  }
  return null;
}

/// Runs in a background isolate.
///
/// Returns null when the photo is already upright, so the caller keeps the
/// original bytes untouched — re-encoding an image that needs no rotation
/// would cost a generation of JPEG quality for nothing.
Uint8List? _bakeSync(Uint8List bytes) {
  final orientation = ImagePrepare.readJpegOrientation(bytes);
  if (orientation == null || orientation == 1) return null;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  // For JPEG the decoder has already applied the rotation and cleared the tag,
  // making this a no-op; it is kept for any other format whose decoder leaves
  // the orientation in place instead.
  final baked = img.bakeOrientation(decoded);

  // encodeJpg writes no EXIF at all, so the output cannot carry a stale
  // orientation that would make an EXIF-aware viewer rotate it a second time.
  // 88 keeps the re-encode visually indistinguishable from the picker's own
  // quality-85 output.
  return img.encodeJpg(baked, quality: 88);
}
