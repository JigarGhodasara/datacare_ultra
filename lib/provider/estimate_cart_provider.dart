import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// One tag captured into a multi-item estimate.
///
/// Values are a **snapshot** taken at the moment the tag was added, not a live
/// reference. The tag estimate screen recomputes its figures whenever the
/// labour, rate or GST filters change, so storing the computed numbers is what
/// keeps a quotation stable while the salesperson moves on to the next item.
@immutable
class EstimateItem {
  final String tagNo;
  final String itemName;
  final String designNo;
  final String pcs;
  final double grossWt;
  final double netWt;
  final double rate;
  final double itemAmount;
  final double labourPrc;
  final double labourRate;
  final double labourAmount;
  final double otherAmount;
  final double netAmount;
  final double gstTax;
  final double totalAmount;

  /// Stone / hallmark / diamond charges for this tag, as returned by BAR_IDTL.
  final List<Map<String, dynamic>> otherDetails;

  /// Product photo, already downloaded. Held as bytes rather than a URL so the
  /// PDF builds from what was on screen when the tag was added, and does not
  /// depend on the network at print time.
  final Uint8List? imageBytes;

  const EstimateItem({
    required this.tagNo,
    required this.itemName,
    this.designNo = '',
    required this.pcs,
    required this.grossWt,
    required this.netWt,
    required this.rate,
    required this.itemAmount,
    required this.labourPrc,
    required this.labourRate,
    required this.labourAmount,
    required this.otherAmount,
    required this.netAmount,
    required this.gstTax,
    required this.totalAmount,
    this.otherDetails = const [],
    this.imageBytes,
  });
}

/// Holds the tags a customer is currently considering.
///
/// Session-only by design — it is not persisted. A cart that survived an app
/// restart would quietly re-open yesterday's customer, which is worse than
/// starting empty.
class EstimateCartProvider extends ChangeNotifier {
  final List<EstimateItem> _items = [];

  List<EstimateItem> get items => List.unmodifiable(_items);

  int get count => _items.length;

  bool get isEmpty => _items.isEmpty;

  bool contains(String tagNo) =>
      _items.any((i) => i.tagNo.trim() == tagNo.trim());

  double get totalPcs =>
      _items.fold(0.0, (s, i) => s + (double.tryParse(i.pcs) ?? 0));

  double get totalGrossWt => _items.fold(0.0, (s, i) => s + i.grossWt);

  double get totalNetWt => _items.fold(0.0, (s, i) => s + i.netWt);

  double get totalItemAmount => _items.fold(0.0, (s, i) => s + i.itemAmount);

  double get totalLabour => _items.fold(0.0, (s, i) => s + i.labourAmount);

  double get totalOther => _items.fold(0.0, (s, i) => s + i.otherAmount);

  double get totalNet => _items.fold(0.0, (s, i) => s + i.netAmount);

  double get totalGst => _items.fold(0.0, (s, i) => s + i.gstTax);

  double get grandTotal => _items.fold(0.0, (s, i) => s + i.totalAmount);

  /// Adds a tag, replacing any earlier snapshot of the same tag so a
  /// recalculated item does not appear twice.
  void add(EstimateItem item) {
    _items.removeWhere((i) => i.tagNo.trim() == item.tagNo.trim());
    _items.add(item);
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
