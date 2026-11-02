import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Optional touch-ups offered after a tag photo is captured.
///
/// Runs on-device in pure Dart — no network call, so customer photos never
/// leave the phone and the feature works in a shop with no signal.
///
/// A "white background" option lived here too, built as a colour flood fill
/// from the edges of the frame. It was removed: matching colours cannot tell
/// jewellery from a shadow or a fold of cloth, so on real shop photos it left
/// jagged edges and halos. Replacing it needs subject segmentation (ML Kit on
/// Android, Vision on iOS 17+) rather than a better threshold.
@immutable
class PhotoEffects {
  /// Auto-levels, a little contrast and saturation, and a light sharpen.
  final bool enhance;

  const PhotoEffects({this.enhance = false});

  bool get isEmpty => !enhance;

  PhotoEffects copyWith({bool? enhance}) =>
      PhotoEffects(enhance: enhance ?? this.enhance);

  @override
  bool operator ==(Object other) =>
      other is PhotoEffects && other.enhance == enhance;

  @override
  int get hashCode => enhance.hashCode;
}

/// Work item for the background isolate.
@immutable
class _EffectRequest {
  final Uint8List bytes;
  final PhotoEffects effects;
  const _EffectRequest(this.bytes, this.effects);
}

class ImageEffects {
  const ImageEffects._();

  /// Applies [effects] to [bytes], returning the re-encoded JPEG.
  ///
  /// Returns [bytes] untouched when no effect is selected, and also when the
  /// image cannot be decoded — a touch-up is a convenience, so failing here
  /// must never cost the user their photo.
  static Future<Uint8List> apply(Uint8List bytes, PhotoEffects effects) async {
    if (bytes.isEmpty || effects.isEmpty) return bytes;
    try {
      final out = await compute(_applySync, _EffectRequest(bytes, effects));
      return out ?? bytes;
    } catch (_) {
      return bytes;
    }
  }
}

Uint8List? _applySync(_EffectRequest request) {
  var image = img.decodeImage(request.bytes);
  if (image == null) return null;
  if (request.effects.enhance) image = enhanceImage(image);
  return img.encodeJpg(image, quality: 90);
}

/// Brightens and sharpens a dull photo.
///
/// Mutates and returns [src] — the underlying `image` filters work in place,
/// and copying a megapixel photo per step would double peak memory on the
/// low-RAM phones this runs on. Callers that still need the original should
/// hold on to the encoded bytes, which is what the upload path does.
///
/// Tuned to be conservative. Jewellery photos are judged on whether the metal
/// and stones look true, so this aims for "same photo, better lit" rather than
/// a heavy filtered look that would misrepresent the piece to a customer.
img.Image enhanceImage(img.Image src) {
  // Auto-levels: stretch the histogram so the darkest pixels reach black and
  // the brightest reach white. This alone fixes most flat, greyish shop photos.
  var out = img.normalize(src, min: 0, max: 255);

  out = img.adjustColor(
    out,
    contrast: 1.06,
    saturation: 1.10,
    brightness: 1.02,
  );

  // Light unsharp-style kernel. Divisor 1 with a centre of 5 against four -1
  // neighbours keeps overall brightness unchanged while lifting edge detail.
  // `amount` blends it back at 55% so chain links and engraving gain
  // definition without the halo a full-strength sharpen would give.
  out = img.convolution(
    out,
    filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
    div: 1,
    amount: 0.55,
  );

  return out;
}
