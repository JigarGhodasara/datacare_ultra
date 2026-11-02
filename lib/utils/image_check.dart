import 'dart:typed_data';
import 'dart:ui' as ui;

/// Result of inspecting a picked photo before it is stored.
enum ImageQuality {
  /// A normal photo with visible detail.
  ok,

  /// Every pixel is (near enough) the same colour — a solid black or white
  /// frame. This is what a failed camera capture or a bad re-encode produces.
  blank,

  /// The whole frame is essentially black, even if not perfectly uniform.
  tooDark,

  /// The bytes could not be decoded as an image at all.
  undecodable,
}

/// Rec. 709 luma. Matching how the eye weights the channels matters here:
/// a pure blue frame is objectively "dark" even though its blue channel is
/// at full scale.
int _luma(int r, int g, int b) => ((r * 2126 + g * 7152 + b * 722) ~/ 10000);

/// Classifies raw RGBA pixels.
///
/// Kept separate from the decode so the thresholds can be unit tested without
/// a Flutter binding.
///
/// Deliberately conservative — a genuine photo of jewellery on a dark cloth is
/// dark but still has structure, so only a frame with (almost) no variation at
/// all is rejected. The cost of a false positive is a needless retake; the cost
/// of a false negative is a black square nobody notices for weeks.
ImageQuality classifyRgba(Uint8List rgba) {
  if (rgba.length < 4) return ImageQuality.undecodable;

  int min = 255;
  int max = 0;
  int sum = 0;
  int count = 0;

  for (var i = 0; i + 3 < rgba.length; i += 4) {
    // Fully transparent pixels carry no visible colour; skip them so a PNG
    // with an alpha border is not judged on its invisible edges.
    if (rgba[i + 3] == 0) continue;
    final l = _luma(rgba[i], rgba[i + 1], rgba[i + 2]);
    if (l < min) min = l;
    if (l > max) max = l;
    sum += l;
    count++;
  }

  if (count == 0) return ImageQuality.blank;

  // A spread this small means a solid fill, whatever the colour.
  if (max - min <= 2) return ImageQuality.blank;

  // Nothing in the frame is brighter than near-black.
  final average = sum / count;
  if (max < 12 && average < 8) return ImageQuality.tooDark;

  return ImageQuality.ok;
}

/// Decodes [encoded] and reports whether it is worth storing.
///
/// Decoded at a small fixed size: sampling ~64x64 is plenty to tell a photo
/// from a blank frame and avoids holding a full-resolution bitmap in memory
/// on low-RAM devices.
Future<ImageQuality> inspectImage(Uint8List encoded) async {
  if (encoded.isEmpty) return ImageQuality.undecodable;
  ui.Image? image;
  try {
    final codec = await ui.instantiateImageCodec(
      encoded,
      targetWidth: 64,
      targetHeight: 64,
    );
    final frame = await codec.getNextFrame();
    image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return ImageQuality.undecodable;
    return classifyRgba(data.buffer.asUint8List());
  } catch (_) {
    return ImageQuality.undecodable;
  } finally {
    image?.dispose();
  }
}

/// Message to show the user for a rejected photo.
String? rejectionMessage(ImageQuality quality) {
  switch (quality) {
    case ImageQuality.ok:
      return null;
    case ImageQuality.blank:
      return 'That photo came out blank. Please take it again.';
    case ImageQuality.tooDark:
      return 'That photo is too dark to save. Please take it again in better '
          'light.';
    case ImageQuality.undecodable:
      return 'That image could not be read. Please choose another photo.';
  }
}
