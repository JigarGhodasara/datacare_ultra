import 'package:flutter/cupertino.dart';

class CommonCompanyYearSelectionProvider extends ChangeNotifier{

  String co_name = '';
  String co_code = '';
  String lc_code = '';
  String co_year = '';
  DateTime? op_date = null;
  DateTime? cl_date = null;
  String webImage = "";
  String webPath = "";
  String userType = "";
  String amountType = "";
  String CoSname = "";
  String sType = "";
  String dType = "";


  void changeCO_name(String name){
    co_name = name;
  }

  void changeCO_code(String code){
    co_code = code;
  }

  void changeLC_code(String code){
    lc_code = code;
  }

  void changeCO_year(String year){
    co_year = year;
  }

  void changeOP_date(DateTime date){
    op_date = date;
  }

  void changeCL_date(DateTime date){
    cl_date = date;
  }

  void changeWebImage(String webImagedata){
    webImage = webImagedata;
    print("Weeb $webImage");
  }

  void changeWebPath(String webPathdata){
    webPath = webPathdata;
    print("web $webPath");
  }

  void changeUserType(String name){
    userType = name;
  }

  void changeAmountType(String name){
    amountType = name;
  }

  void changeCoSName(String name){
    CoSname = name;
    print(CoSname);
  }
  void changesType(String name){
    sType = name;
    print(sType);
  }
  void changedType(String name){
    dType = name;
    print(dType);
  }
}