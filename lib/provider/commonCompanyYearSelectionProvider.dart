import 'package:flutter/cupertino.dart';

class CommonCompanyYearSelectionProvider extends ChangeNotifier {
  String co_name = '';
  String co_code = '';
  String lc_code = '';
  String co_year = '';
  DateTime? op_date = null;
  DateTime? cl_date = null;
  String webImage = "";
  String webPath = "";

  /// The server address the app is connected to, as typed on the settings
  /// screen. Used to re-point a WEB_PATH that names the shop's own LAN
  /// address, which is unreachable when connecting over a static public IP.
  String serverHost = "";
  String userType = "";
  String amountType = "";
  String CoSname = "";
  String sType = "";
  String dType = "";
  String hdd = "";

  void changeCO_name(String name) {
    co_name = name;
  }

  void changeCO_code(String code) {
    co_code = code;
  }

  void changeLC_code(String code) {
    lc_code = code;
  }

  void changeCO_year(String year) {
    co_year = year;
  }

  void changeOP_date(DateTime date) {
    op_date = date;
  }

  void changeCL_date(DateTime date) {
    cl_date = date;
  }

  // Trimmed on the way in: WEB_IMAGE and WEB_PATH are space-padded CHAR
  // columns, and the iOS SQL driver keeps that padding while Android strips
  // it. Normalising here fixes every consumer at once.
  void changeWebImage(String webImagedata) {
    webImage = webImagedata.trim();
    print("Weeb $webImage");
  }

  void changeServerHost(String? host) {
    serverHost = (host ?? '').trim();
    notifyListeners();
  }

  void changeWebPath(String webPathdata) {
    webPath = webPathdata.trim();
    print("web $webPath");
  }

  void changeUserType(String name) {
    userType = name;
  }

  void changeAmountType(String name) {
    amountType = name;
  }

  void changeCoSName(String name) {
    CoSname = name;
    print(CoSname);
  }

  void changesType(String name) {
    sType = name;
    print(sType);
  }

  void changedType(String name) {
    dType = name;
    print(dType);
  }

  void changedHdd(String hddName) {
    hdd = hddName;
    print(hdd);
  }
}
