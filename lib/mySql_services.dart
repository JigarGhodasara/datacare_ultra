import 'dart:ffi';

import 'package:DataCareUltra/utils/keys.dart';
import 'package:DataCareUltra/utils/preffrance.dart';
import 'package:flutter/services.dart';

class MySQLService {
  static const MethodChannel _channel = MethodChannel('sql_client_channel');

  Future<dynamic> connectToDatabase({String? dbName}) async {
    String? host =
    await Preffrance().getString(Keys.HOST);
    String? userName =
    await Preffrance().getString(Keys.USERNAME);
    String? password =
    await Preffrance().getString(Keys.PASSWORD);
    String? db =
    dbName ?? await Preffrance().getString(Keys.DATABASE);
    //     host: "45.120.139.237",
    //     port: 1433,
    //     databaseName: "NextMain",
    //     userName: "sa",
    //     password: "datacare@123",
    try {
      final result = await _channel.invokeMethod('connectAndQuery',{
        "host":host,
        "databaseName":db,
        "userName":userName,
        "password":password
      });
      print("result $result");
      return result;
    } on PlatformException catch (e) {
      print("Failed to connect: '${e.message}'.");
    }
  }

  Future<dynamic> Login(String userName) async {
      final result2 = await _channel.invokeMethod('Login',{
        "loginUserName": userName
      });
      print("result2 $result2");
      return result2;
    }

  Future<dynamic> getForImage(String coCode) async {
    final getForImage = await _channel.invokeMethod('getForImage',{
      "coCode": coCode
    });
    print("getForImage $getForImage");
    return getForImage;
  }
  Future<dynamic> getRateSetting(String coCode) async {
    final getRateSetting = await _channel.invokeMethod('getRateSetting',{
      "coCode": coCode
    });
    print("getRateSetting $getRateSetting");
    return getRateSetting;
  }

  Future<dynamic> getCompanyData() async {
    final companyData = await _channel.invokeMethod('getCompanyData');
    print("CompanyData $companyData");
    return companyData;
  }

  Future<dynamic> getCompanyLocation(String coCode) async {
    final companyLocation = await _channel.invokeMethod('getCompanyLocation',{
      "coCode": coCode
    });
    print("companyLocation $companyLocation");
    return companyLocation;
  }

  Future<dynamic> getYears(String coCode) async {
    final years = await _channel.invokeMethod('getYears',{
      "coCode": coCode
    });
    print("Years $years");
    return years;
  }

  Future<dynamic> getRates(String coCode,String lcCode,String date) async {
    final rates = await _channel.invokeMethod('getRates',{
      "coCode": coCode,
      "lcCode": lcCode,
      "date": date,

    });
    print("rate $rates");
    return rates;
  }

  Future<dynamic> getLedgerReportData(String coCode,String lcCode,String date,bool checkBox,String grp,String city,String area) async {
    final ledgerReportData = await _channel.invokeMethod('getLedgerReportData',{
      "coCode": coCode,
      "lcCode": lcCode,
      "date": date,
      "checkBox" : checkBox,
      "grp":grp,
      "city":city,
      "area":area
    });
    print("ladgerReportData $ledgerReportData");
    return ledgerReportData;
  }

  Future<dynamic> getProductCategory(String coCode,String itType) async {
    final productCategory = await _channel.invokeMethod('getProductCategory',{
      "coCode": coCode,
      "itType": itType,
    });
    print("productCategory $productCategory");
    return productCategory;
  }

  Future<dynamic> getProducts(String coCode,String lcCode,String year,String prCode,String itType,String grpCode) async {
    final getProducts = await _channel.invokeMethod('getProducts',{
      "coCode": coCode,
      "lcCode": lcCode,
      "year": year,
      "prCode": prCode,
      "itType": itType,
      "grpCode":grpCode
    });
    print("getProducts $getProducts");
    return getProducts;
  }


  Future<dynamic> getStockReport(
      {
       required String coCode,
     required String lcCode,
     required String year,
     required String fromDate,
     required String toDate,
     required String itType,
     required String stkType,
      required String grpCode,
      required String itmCode,
      required String prdCode,
      required String tblCode,
      }) async {
    final getStockReport = await _channel.invokeMethod('getStockReport',{
      "coCode": coCode,
      "lcCode": lcCode,
      "year": year,
      "date":fromDate,
      "toDate":toDate,
      "itType": itType,
      "stkType": stkType,
      "grpCode": grpCode,
      "itmCode": itmCode,
      "prdCode": prdCode,
      "tblCode":tblCode,
    });
    print("getStockReport $getStockReport");
    return getStockReport;
  }

  Future<dynamic> getPhoneBookData(String coCode) async {
    final getPhoneBookData = await _channel.invokeMethod('getPhoneBookData',{
      "coCode": coCode
    });
    print("getPhoneBookData $getPhoneBookData");
    return getPhoneBookData;
  }

  Future<dynamic> getSalesReport(String coCode,String lcCode,String year,String fromDate,String toDate,String selectedBook) async {
    final getSalesReport = await _channel.invokeMethod('getSalesReport',{
      "coCode": coCode,
      "lcCode": lcCode,
      "year": year,
      "fromDate": fromDate,
      "toDate": toDate,
      "selectedBook":selectedBook
    });
    print("getSalesReport $getSalesReport");
    return getSalesReport;
  }

  Future<dynamic> getSalesFilterData(String coCode,String lcCode) async {
    final getSalesFilterData = await _channel.invokeMethod('getSalesFilterData',{
      "coCode": coCode,
      "lcCode": lcCode,
    });
    print("getSalesFilterData $getSalesFilterData");
    return getSalesFilterData;
  }

  Future<dynamic> getStockFilterGrpData(String coCode) async {
    final getStockFilterGrpData = await _channel.invokeMethod('getStockFilterGrpData',{
      "coCode": coCode
    });
    print("getStockFilterGrpData $getStockFilterGrpData");
    return getStockFilterGrpData;
  }


  Future<dynamic> getStockFilterItmData(String coCode) async {
    final getStockFilterItmData = await _channel.invokeMethod('getStockFilterItmData',{
      "coCode": coCode
    });
    print("getStockFilterItmData $getStockFilterItmData");
    return getStockFilterItmData;
  }

  Future<dynamic> getStockFilterPrdData(String coCode) async {
    final getStockFilterPrdData = await _channel.invokeMethod('getStockFilterPrdData',{
      "coCode": coCode
    });
    print("getStockFilterPrdData $getStockFilterPrdData");
    return getStockFilterPrdData;
  }

  Future<dynamic> getStockFilterTblData(String coCode,String lcCode) async {
    final getStockFilterTblData = await _channel.invokeMethod('getStockFilterTblData',{
      "coCode": coCode,
      "lcCode":lcCode,
    });
    print("getStockFilterTblData $getStockFilterTblData");
    return getStockFilterTblData;
  }

  Future<dynamic> getTagEstimateData(String coCode,String lcCode,String year,String tagNo,String VchsrNo) async {

    final getTagEstimateData = await _channel.invokeMethod('getTagEstimateData',{
      "coCode": coCode,
      "lcCode":lcCode,
      "year":year,
      "tagNo":tagNo,
      "VchsrNo":VchsrNo
    });
    print("getTagEstimateData $getTagEstimateData");
    return getTagEstimateData;
  }

  Future<dynamic> getWhSalesReport(String coCode,String lcCode,String year,String fromDate,String toDate) async {
    final getWhSalesReport = await _channel.invokeMethod('getWhSalesReport',{
      "coCode": coCode,
      "lcCode":lcCode,
      "year":year,
      "fromDate":fromDate,
      "toDate":toDate
    });
    print("getWhSalesReport $getWhSalesReport");
    return getWhSalesReport;
  }

  Future<dynamic> getSalesOrderReport(String coCode,String lcCode,String bookType,String fromDate,String toDate) async {
    final getSalesOrderReport = await _channel.invokeMethod('getSalesOrderReport',{
      "coCode": coCode,
      "lcCode":lcCode,
      "bookType":bookType,
      "fromDate":fromDate,
      "toDate":toDate
    });
    print("getSalesOrderReport $getSalesOrderReport");
    return getSalesOrderReport;
  }

  Future<dynamic> getGroup(String coCode) async {
    final getGroup = await _channel.invokeMethod('getGroup',{
      "coCode": coCode
    });
    print("getGroup $getGroup");
    return getGroup;
  }

  Future<dynamic> getCity(String coCode,String lcCode) async {
    final getCity = await _channel.invokeMethod('getCity',{
      "coCode": coCode,
      "lcCode": lcCode
    });
    print("getCity $getCity");
    return getCity;
  }

  Future<dynamic> getArea(String coCode,String lcCode) async {
    final getArea = await _channel.invokeMethod('getArea',{
      "coCode": coCode,
      "lcCode": lcCode
    });
    print("getArea $getArea");
    return getArea;
  }

  Future<dynamic> getDailyRates(String coCode,String lcCode,String date) async {
    final getDailyRates = await _channel.invokeMethod('getDailyRates',{
      "coCode": coCode,
      "lcCode": lcCode,
      "date":date
    });
    print("getDailyRates $getDailyRates");
    return getDailyRates;
  }


    Future<dynamic> getSOftType() async {
    final getSOftType = await _channel.invokeMethod('getSOftType');
    print("getSOftType $getSOftType");
    return getSOftType;
  }

  Future<dynamic> deleteImage(String coCode,String lcCode,String tagNo,String vchrNo) async {
    final deleteImage = await _channel.invokeMethod('deleteImage',{
      "coCode": coCode,
      "lcCode": lcCode,
      "tagNo":tagNo,
      "vchrNo":vchrNo
    });
    print("deleteImage $deleteImage");
    return deleteImage;
  }

  Future<dynamic> insertImage(String coCode,String lcCode,String tagNo,String vchrNo,String base64Image) async {
    final insertImage = await _channel.invokeMethod('insertImage',{
      "coCode": coCode,
      "lcCode": lcCode,
      "tagNo":tagNo,
      "vchrNo":vchrNo,
      "base64Image":base64Image
    });
    print("insertImage $insertImage");
    return insertImage;
  }

  Future<dynamic> getCompanyDetail(String coCode) async {
    final getCompanyDetail = await _channel.invokeMethod('getCompanyDetail',{
      "coCode": coCode,
    });
    print("getCompanyDetail $getCompanyDetail");
    return getCompanyDetail;
  }

  Future<dynamic> getZoomingLedgerReport(String coCode,String lcCode,String acCode) async {
    final getZoomingLedgerReport = await _channel.invokeMethod('getZoomingLedgerReport',{
      "coCode": coCode,
      "lcCode": lcCode,
      "acCode": acCode
    });
    print("getZoomingLedgerReport $getZoomingLedgerReport");
    return getZoomingLedgerReport;
  }
  }