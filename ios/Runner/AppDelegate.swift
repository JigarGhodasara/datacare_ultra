import UIKit
import Flutter

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
    
    var sqlClient: SQLClient?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let sqlClientChannel = FlutterMethodChannel(name: "sql_client_channel", binaryMessenger: controller.binaryMessenger)

        sqlClientChannel.setMethodCallHandler { [weak self] (call, result) in
            if call.method == "connectAndQuery" {
                let args = call.arguments as! Dictionary<String, Any>
                let host = args["host"] as! String
                let username = args["userName"] as! String
                let password = args["password"] as! String
                let database = args["databaseName"] as! String
                
                self?.connectAndQuery(result: result,host: host,username: username,password: password,database: database)
            }
            else if call.method == "Login" {
                let args = call.arguments as! Dictionary<String, Any>
                let loginUsername = args["loginUserName"] as! String
                self?.login(result: result, username: loginUsername)
            }
            else if call.method == "getCompanyData" {
                self?.getCompanyData(result: result)
            }
            else if call.method == "getCompanyLocation" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getCompanyLocation(result: result, coCode: args["coCode"] as! String)
            }
            else if call.method == "getYears" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getYears(result: result, coCode: args["coCode"] as! String)
            }
            else if call.method == "getRates" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getRates(result: result, coCode: args["coCode"] as! String,lcCode: args["lcCode"] as! String,date: args["date"] as! String)
            }
            else if call.method == "getLedgerReportData" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getLedgerReportData(result: result, coCode: args["coCode"] as! String,lcCode: args["lcCode"] as! String,date: args["date"] as! String,checkBox: args["checkBox"] as! Bool,grp: args["grp"] as! String,city: args["city"] as! String,area: args["area"] as! String)
            }
            else if call.method == "getProductCategory" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getProductCategory(result: result, coCode: args["coCode"] as! String,itType: args["itType"] as! String)
            }
            else if call.method == "getProducts" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getProducts(result: result,
                                  coCode: args["coCode"] as! String,
                                  lcCode: args["lcCode"] as! String,
                                  year:args["year"] as! String,
                                  prCode: args["prCode"] as! String,
                                  itType: args["itType"] as! String,
                                  grpCode: args["grpCode"] as! String
                )
            }
            else if call.method == "getStockReport" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getStockReport(
                    result: result,
                    coCode: args["coCode"] as! String,
                    lcCode: args["lcCode"] as! String,
                    year:args["year"] as! String,
                    date: args["date"] as! String,
                    ToDate: args["toDate"] as! String,
                    itType: args["itType"] as! String,
                    stkType: args["stkType"] as! String,
                    grpCode: args["grpCode"] as! String,
                    itmCode: args["itmCode"] as! String,
                    prdCode: args["prdCode"] as! String,
                    tblCode: args["tblCode"] as! String
                )
            }
            else if call.method == "getPhoneBookData" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getPhoneBookData(result: result, coCode: args["coCode"] as! String)
            }
            else if call.method == "getForImage" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getForImage(result: result, coCode: args["coCode"] as! String)
            }
            else if call.method == "getRateSetting" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getRateSetting(result: result, coCode: args["coCode"] as! String)
            }
            else if call.method == "getSalesReport" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getSalesReport(result: result, coCode: args["coCode"] as! String,lcCode: args["lcCode"] as! String,year: args["year"] as! String,fromDate: args["fromDate"] as! String,toDate: args["toDate"] as! String,selectedBook : args["selectedBook"] as! String)
            }
            else if call.method == "getSalesFilterData" {
                let args = call.arguments as! Dictionary<String,Any>
                self?.getSalesFilterData(result: result, coCode:args["coCode"] as! String,lcCode: args["lcCode"] as! String)
            }
            else if call.method == "getStockFilterGrpData" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getStockFilterGrpData(result: result, coCode: args["coCode"] as! String)
            }
            else if call.method == "getStockFilterItmData" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getStockFilterItmData(result: result, coCode: args["coCode"] as! String)
            }
            else if call.method == "getStockFilterPrdData" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getStockFilterPrdData(result: result, coCode: args["coCode"] as! String)
            }
            else if call.method == "getStockFilterTblData" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getStockFilterTblData(
                    result: result,
                    coCode: args["coCode"] as! String,
                    lcCode:args["lcCode"] as! String
                )
            }
            else if call.method == "getTagEstimateData" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getTagEstimateData(result: result, coCode: args["coCode"] as! String, lcCode: args["lcCode"] as! String, year: args["year"] as! String, tagNo: args["tagNo"] as! String, VchsrNo: args["VchsrNo"] as! String)
            }
            else if call.method == "getWhSalesReport" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getWhSalesReport(result: result, coCode: args["coCode"] as! String, lcCode: args["lcCode"] as! String, year: args["year"] as! String, fromDate: args["fromDate"] as! String, toDate: args["toDate"] as! String)
            }
            else if call.method == "getSalesOrderReport" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getSalesOrderReport(result: result, coCode: args["coCode"] as! String, lcCode: args["lcCode"] as! String, bookType: args["bookType"] as! String, fromDate: args["fromDate"] as! String, toDate: args["toDate"] as! String)
            }
            else if call.method == "getGroup" {
                            let args = call.arguments as! Dictionary<String, Any>
                            self?.getGroup(result: result, coCode: args["coCode"] as! String)
                        }
            else if call.method == "getCity" {
                            let args = call.arguments as! Dictionary<String, Any>
                self?.getCity(result: result, coCode: args["coCode"] as! String, lcCode: args["lcCode"] as! String)
                        }
            else if call.method == "getArea" {
                            let args = call.arguments as! Dictionary<String, Any>
                self?.getArea(result: result, coCode: args["coCode"] as! String,lcCode: args["lcCode"] as! String)
                        }
            else if call.method == "getDailyRates" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getDailyRates(result: result, coCode: args["coCode"] as! String, lcCode: args["lcCode"] as! String, date: args["date"] as! String)
            }
            else if call.method == "getSOftType" {
                self?.getSOftType(result: result)
            }
            else if call.method == "deleteImage" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.deleteImage(result: result, coCode: args["coCode"] as! String, lcCode: args["lcCode"] as! String, tagNo: args["tagNo"] as! String, vchrNo: args["vchrNo"] as! String)
            }
            else if call.method == "insertImage" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.insertImage(result: result, coCode: args["coCode"] as! String, lcCode: args["lcCode"] as! String, tagNo: args["tagNo"] as! String, vchrNo: args["vchrNo"] as! String, base64Image: args["base64Image"] as! String)
            }
            else if call.method == "getCompanyDetail" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getCompanyDetail(result: result, coCode: args["coCode"] as! String)
            }
            else if call.method == "getZoomingLedgerReport" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getZoomingLedgerReport(result: result, coCode: args["coCode"] as! String,lcCode: args["lcCode"] as! String,acCode: args["acCode"] as! String)
            }
            else if call.method == "getZoomingStockReport" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getZoomingStockReport(result: result, coCode: args['coCode'] as! String , lcCode: args['lcCode'] as! String, itCode: args['itCode'] as! String,fromDate: args['fromDate'] as! String, toDate: args['toDate'] as! String,selectedValue: args['selectedValue'] as! String)
            }
            else if call.method == "getZoomingSalesInvoiceDetails" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getZoomingSalesInvoiceDetails(result: result, coCode: args['coCode'] as! String , lcCode: args['lcCode'] as! String, vchNo: args['vchNo'] as! String,coBook: args['coBook'] as! String)
            }
            else if call.method == "getZoomingSalesProductDetails" {
                let args = call.arguments as! Dictionary<String, Any>
                self?.getZoomingSalesProductDetails(result: result, coCode: args['coCode'] as! String , lcCode: args['lcCode'] as! String, vchNo: args['vchNo'] as! String,coBook: args['coBook'] as! String)
            }
            else {
                result(FlutterMethodNotImplemented)
            }
        }
        GeneratedPluginRegistrant.register(with: self)  // Ensure this line is here
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func connectAndQuery(result: @escaping FlutterResult,host:String,username:String,password:String,database:String) {
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.disconnect()
        sqlClient?.connect(host, username: username, password: password, database: database, completion: { isSuccess in
//            print(self.sqlClient.debugDescription)
            result(isSuccess)
        })
    }
    private func login(result: @escaping FlutterResult,username:String) {
        print("INside login from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute("SELECT LOGIN_NAME,LOGIN_PWD,LOGIN_CATG FROM LOGIN_MAST WHERE LOGIN_NAME = '" +
                           username +
                           "'") { results in
            result(results)
        };
    }
    private func getCompanyData(result: @escaping FlutterResult) {
        print("INside getCompanyData from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute("SELECT CO_CODE As CoCode,CO_NAME as NameT,CO_SNAME FROM CO_MAST ORDER BY CO_CODE") { results in
            result(results)
        };
    }
    private func getCompanyLocation(result: @escaping FlutterResult,coCode:String) {
        print("INside getCompanyLocation from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute("SELECT LC_CODE,LC_NAME FROM LOCT_MAST WHERE CO_CODE = '" +
                           coCode +
                           "'AND LC_CODE <> '' ORDER BY LC_CODE") { results in
            result(results)
        };
    }
    private func getYears(result: @escaping FlutterResult,coCode:String) {
        print("INside getYears from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute("SELECT CO_YEAR As Year FROM YEAR_MAST WHERE CO_CODE = '" +
                           coCode +
                           "' ORDER BY CO_YEAR desc") { results in
            result(results)
        };
    }
    private func getRates(result: @escaping FlutterResult,coCode:String,lcCode:String,date:String) {
        print("INside getYears from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute("SELECT FINE_GL_RATE,FINE_SL_RATE,A.VCH_DATE FROM RATE_MAST AS A INNER JOIN GROUP_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.GR_CODE = B.GR_CODE WHERE A.CO_CODE = '" +
                           coCode +
                           "' AND A.LC_CODE = '" +
                           lcCode +
                           "' AND A.VCH_DATE <= '" +
                           date +
                           "' AND B.RATE_DISPLAY = 'Y'GROUP BY FINE_GL_RATE,FINE_SL_RATE,A.VCH_DATE ORDER BY A.VCH_DATE DESC ") { results in
            result(results)
        };
    }
    private func getLedgerReportData(result: @escaping FlutterResult,coCode:String,lcCode:String,date:String,checkBox:Bool,grp:String,city:String,area:String) {
        print("INside getLedgerReportData from xcode")
        sqlClient = SQLClient.sharedInstance()
        var query = ""
          query = "Select ROW_NUMBER() OVER (ORDER BY B.AC_NAME) AS SrNo,A.AC_CODE,B.AC_NAME,B.AC_ADD1,B.AC_MOBILE,B.AC_REF_NAME As AC_REFBY,B.AC_CITY,B.AC_KHATA_NO,  Case When SUM(A.CR_AMT-A.DR_AMT) < 0 Then abs(SUM(A.CR_AMT-A.DR_AMT)) Else 0 End As DrAmt,  Case When SUM(A.CR_AMT-A.DR_AMT) > 0 Then abs(SUM(A.CR_AMT-A.DR_AMT)) Else 0 End As CrAmt,  Case When SUM(Case When A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) < 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end As DrGold,  Case When SUM(Case When A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) > 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end As CrGold,  Case WHEN SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) < 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end As DrSilver,  Case WHEN SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) > 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end As CrSilver  FROM AC_DATA AS A LEFT JOIN AC_MAST AS B ON A.CO_CODE = B.CO_CODE And A.AC_CODE = B.AC_CODE WHERE A.CO_CODE = '" +
            coCode +
            "' AND A.LC_CODE = '" +
            lcCode +
            "' and A.VCH_DATE <= '" +
            date +
            "'"

        if grp != "" {
            query += "AND B.AC_GR = '"+grp+"'"
        }
        if city != "" {
            query += "AND B.AC_CITY = '"+city+"'"
        }
        if area != "" {
            query += "AND B.AC_AREA = '"+area+"'"
        }
        
        if checkBox {
            query += "GROUP BY A.AC_CODE,B.AC_NAME,B.AC_ADD1,B.AC_MOBILE,B.AC_REF_NAME,B.AC_CITY,B.AC_KHATA_NO ORDER BY B.AC_NAME"
        }else {
            query += "GROUP BY A.AC_CODE,B.AC_NAME,B.AC_ADD1,B.AC_MOBILE,B.AC_REF_NAME,B.AC_CITY,B.AC_KHATA_NO  HAVING (round(Case When SUM(A.CR_AMT-A.DR_AMT) < 0 Then abs(SUM(A.CR_AMT-A.DR_AMT)) Else 0 End,2)) +  (round(Case WHEN SUM(A.CR_AMT-A.DR_AMT) > 0 Then abs(SUM(A.CR_AMT-A.DR_AMT)) Else 0 End,2)) +  (format(Case WHEN SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) < 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end,'0.000')) +  (format(Case When SUM(Case When A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) > 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'G' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end,'0.000')) +  (format(Case WHEN SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) < 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end,'0.00'))+  (format(Case WHEN SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END) > 0 then abs(SUM(CASE WHEN A.IT_TYPE = 'S' THEN (CASE WHEN A.SIGN = '+' THEN A.FINE_WT ELSE -A.FINE_WT END )ELSE 0 END)) else 0 end,'0.00')) <> 0  ORDER BY B.AC_NAME"
        }
        
        
        sqlClient?.execute(query) { results in
            result(results)
        };
    }
    private func getProductCategory(result: @escaping FlutterResult,coCode:String,itType:String) {
        print("INside getLedgerReportData from xcode")
        sqlClient = SQLClient.sharedInstance()
    var runQuery = "SELECT B.PR_CODE,C.PR_NAME FROM (MAIN_STOCK AS A INNER JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE) " +
        "INNER JOIN PRODUCT_MAST AS C ON B.CO_CODE = C.CO_CODE AND B.PR_CODE = C.PR_CODE WHERE A.CO_CODE = '" +
        coCode +
        "' AND A.TAG_NO <> 'N' "
        
        if itType != "" {
            runQuery += " AND B.IT_TYPE = '" + itType + "'"
        }
        runQuery += " GROUP BY B.PR_CODE,C.PR_NAME ORDER BY PR_NAME";
        sqlClient?.execute(runQuery) { results in
            result(results)
        };
        
    }
    private func getProducts(result: @escaping FlutterResult,coCode:String,lcCode:String,year:String,prCode:String,itType:String,grpCode:String) {
        print("INside getProducts from xcode")
        sqlClient = SQLClient.sharedInstance()
    var runQuery = "SELECT A.TAG_NO As TagNo,B.IT_NAME As ItmName,D.PR_CODE,C.ITM_SIZE As Size,C.ITM_PCS as Pcs,C.ITM_GWT As Grwt,C.ITM_NWT AS NetWt,C.LBR_PRC As LbrPrc,C.LBR_RATE As LRate,C.LBR_AMT LbrAmt,C.OTH_AMT OthAmt,C.ITM_MRP As Mrp,C.VCH_SRNO,C.LBR_TYPE AS LbrType,C.RATE_TYPE AS RateType,B.GR_CODE as GrCode from ((MAIN_STOCK AS A INNER JOIN BAR_DETL AS C ON A.CO_CODE = C.CO_CODE  And A.TAG_NO = C.TAG_NO And A.VCH_SRNO = C.VCH_SRNO And A.IT_CODE = C.IT_CODE) LEFT JOIN  ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE And A.IT_CODE = B.IT_CODE) LEFT JOIN PRODUCT_MAST AS D ON B.CO_CODE = D.CO_CODE And B.PR_CODE = D.PR_CODE WHERE A.CO_CODE = '"+coCode+"' AND A.LC_CODE = '"+lcCode+"' AND A.CO_YEAR = '"+year+"'";
        
        if itType != "" {
            runQuery += " AND B.IT_TYPE = '" + itType + "'"
        }
        if prCode != "" {
            runQuery += "AND D.PR_CODE = '"+prCode+"' "
        }
        if grpCode != "" {
            runQuery += "AND B.GR_CODE = '" + grpCode + "' "
        }
        runQuery += "GROUP BY D.PR_CODE,A.TAG_NO,B.IT_NAME,B.IT_CODE,C.ITM_SIZE,C.ITM_PCS,C.ITM_GWT,C.ITM_NWT,C.LBR_PRC,C.LBR_RATE,C.LBR_AMT,C.OTH_AMT,  C.ITM_MRP,C.VCH_SRNO,C.LBR_TYPE,C.RATE_TYPE, B.GR_CODE HAVING SUM(CASE WHEN ITM_SIGN='+' THEN A.VCH_SRNO ELSE -A.VCH_SRNO END) > 0  ORDER BY A.TAG_NO DESC";
        sqlClient?.execute(runQuery) { results in
         print(results)
            result(results)
        };
        
    }
    private func getStockReport(
        result: @escaping FlutterResult,
        coCode:String,
        lcCode:String,
        year:String,
        date:String,
        ToDate:String,
        itType:String,
        stkType:String,
        grpCode:String,
        itmCode:String,
        prdCode:String,
        tblCode:String
    ) {
        print("INside getProducts from xcode")
        sqlClient = SQLClient.sharedInstance()
    var runQuery = "SELECT B.IT_CODE AS ItCode ,B.IT_NAME AS ItName,B.IT_TYPE As ItType, SUM(CASE WHEN A.VCH_DATE <  '"+date+"' THEN (CASE WHEN ITM_SIGN = '+' THEN  A.ITM_PCS ELSE  -A.ITM_PCS END) ELSE 0 END) AS OpPcs,SUM(CASE WHEN A.VCH_DATE <  '"+date+"' THEN (CASE WHEN ITM_SIGN = '+' THEN A.ITM_NWT ELSE -A.ITM_NWT END) ELSE 0 END) AS OpWt,SUM(CASE WHEN A.VCH_DATE >= '"+date+"' AND A.VCH_DATE <= '"+ToDate+"'  THEN (CASE WHEN ITM_SIGN = '+' AND TR_TYPE = 'P' THEN A.ITM_PCS ELSE 0 END) ELSE 0 END) AS PrPcs,SUM(CASE WHEN A.VCH_DATE >= '"+date+"' AND A.VCH_DATE <= '"+ToDate+"'  THEN (CASE WHEN ITM_SIGN = '+' AND TR_TYPE = 'P' THEN A.ITM_NWT ELSE 0 END) ELSE 0 END) AS PrWt,SUM(CASE WHEN A.VCH_DATE >= '"+date+"' AND A.VCH_DATE <= '"+ToDate+"'  THEN (CASE WHEN ITM_SIGN = '+' AND TR_TYPE = 'I' THEN A.ITM_PCS ELSE 0 END) ELSE 0 END) AS InPcs,SUM(CASE WHEN A.VCH_DATE >= '"+date+"' AND A.VCH_DATE <= '"+ToDate+"'  THEN (CASE WHEN ITM_SIGN = '+' AND TR_TYPE = 'I' THEN A.ITM_NWT ELSE 0 END) ELSE 0 END) AS InWt, SUM(CASE WHEN A.VCH_DATE >= '"+date+"' AND A.VCH_DATE <= '"+ToDate+"'  THEN (CASE WHEN ITM_SIGN = '-' AND TR_TYPE = 'O' THEN A.ITM_PCS ELSE 0 END) ELSE 0 END) AS OutPcs,SUM(CASE WHEN A.VCH_DATE >= '"+date+"' AND A.VCH_DATE <= '"+ToDate+"'  THEN (CASE WHEN ITM_SIGN = '-' AND TR_TYPE = 'O' THEN A.ITM_NWT ELSE 0 END) ELSE 0 END) AS OutWt,SUM(CASE WHEN A.VCH_DATE >= '"+date+"' AND A.VCH_DATE <= '"+ToDate+"'  THEN (CASE WHEN ITM_SIGN = '-' AND TR_TYPE = 'S' THEN A.ITM_PCS ELSE 0 END) ELSE 0 END) AS SlPcs,SUM(CASE WHEN A.VCH_DATE >= '"+date+"' AND A.VCH_DATE <= '"+ToDate+"'  THEN (CASE WHEN ITM_SIGN = '-' AND TR_TYPE = 'S' THEN A.ITM_NWT ELSE 0 END) ELSE 0 END) AS SlWt,SUM(CASE WHEN A.VCH_DATE <=  '"+ToDate+"' THEN(CASE WHEN ITM_SIGN = '+' THEN A.ITM_PCS ELSE -A.ITM_PCS END) ELSE 0 END) AS ClPcs,SUM(CASE WHEN A.VCH_DATE <=  '"+ToDate+"' THEN(CASE WHEN ITM_SIGN = '+' THEN A.ITM_NWT ELSE -A.ITM_NWT END) ELSE 0 END) AS ClWt FROM MAIN_STOCK AS A LEFT JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE WHERE A.CO_CODE = '"+coCode+"' AND A.LC_CODE = '"+lcCode+"' AND A.CO_YEAR = '"+year+"'"
        
        if itType != "" {
            runQuery += "AND B.IT_TYPE = '" + itType + "' "
        }
        if "I" == stkType {
            runQuery += "AND A.TAG_NO ='N' "
        }
        if "T" == stkType {
            runQuery += "AND A.TAG_NO <> 'N' "
        }
        if grpCode != ""{
            runQuery += "AND B.GR_CODE = '" + grpCode + "' ";
        }
        if itmCode != ""{
            runQuery += "AND B.IT_NAME = '" + itmCode + "' ";
        }
        if prdCode != ""{
            runQuery += "AND B.PR_CODE = '" + prdCode + "' ";
        }
        if tblCode != ""{
            runQuery += "AND B.TBL_CODE <> '" + tblCode + "' ";
        }
        runQuery += "GROUP BY B.IT_CODE,B.IT_NAME,B.IT_TYPE ORDER BY B.IT_NAME";
        
        print(runQuery)
        sqlClient?.execute(runQuery) { results in
            result(results)
        };
        
    }
    private func getPhoneBookData(result: @escaping FlutterResult,coCode:String) {
        print("INside getPhoneBookData from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute("SELECT AC_CODE,AC_NAME,AC_CITY,AC_MOBILE,AC_AREA,AC_EMAIL,AC_ADD1,AC_ADD2,AC_ADD3 FROM AC_MAST WHERE CO_CODE = '" + coCode + "' AND AC_GR IN ('00','01','04','05','10','15','20') AND AC_MOBILE IS NOT NULL AND AC_MOBILE != '' ORDER BY AC_NAME") { results in
            result(results)
        };
    }
    private func getForImage(result: @escaping FlutterResult,coCode:String) {
        print("INside getForImage from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute("SELECT WEB_IMAGE,WEB_PATH FROM CO_SET_NEW WHERE CO_CODE ='" + coCode + "' ") { results in
            print(results)
            result(results)
        };
    }
    private func getRateSetting(result: @escaping FlutterResult,coCode:String) {
        print("INside getRateSetting from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute("SELECT SL_AMT_TYPE FROM CO_SET WHERE CO_CODE ='" +
                           coCode +
                           "' ") { results in
            print(results)
            result(results)
        };
    }
    private func getSalesReport(result: @escaping FlutterResult,coCode:String,lcCode:String,year:String,fromDate:String,toDate:String,selectedBook:String) {
        print("INside getSalesReport from xcode")
        sqlClient = SQLClient.sharedInstance()
        
        var query = "SELECT A.CO_CODE,A.LC_CODE,A.CO_YEAR,(convert(varchar(50),A.VCH_DATE,105)) as VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_NAME,C.AC_NAME,C.AC_MOBILE, A.MAIN_USER, SUM(ITM_PCS) As Pcs,Sum(A.ITM_GWT) As Gwt,SUM(A.ITM_NWT) As Nwt,SUM(A.ITM_FINE) As Fine, (Select D.TOT_AMT From SL_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.LC_CODE = D.LC_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As NetAmt, (Select E.BILL_OS From SL_DATA AS E Where A.CO_CODE = E.CO_CODE AND A.LC_CODE = E.LC_CODE AND A.CO_YEAR = E.CO_YEAR AND A.CO_BOOK = E.CO_BOOK  AND A.VCH_NO = E.VCH_NO ) As OsAmt from (MAIN_STOCK AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE = B.CO_CODE AND A.LC_CODE = B.LC_CODE AND A.CO_BOOK = B.CO_BOOK) LEFT JOIN AC_MAST AS C ON A.CO_CODE = C.CO_CODE AND A.AC_CODE = C.AC_CODE WHERE A.CO_CODE = '"+coCode+"' AND A.LC_CODE = '"+lcCode+"' AND A.CO_YEAR = '"+year+"' AND A.ITM_SIGN = '-' AND A.VCH_DATE >= '"+fromDate+"' AND A.VCH_DATE <= '"+toDate+"' AND B.MAIN_BOOK IN ('SALES','SALES RETURN') "
        
        // is for fillter

               if selectedBook != "Select book" {
                   query += "AND A.CO_BOOK = '"+selectedBook.split(separator: "-")[0]+"' "
               }
        
        query += "GROUP BY A.CO_CODE,A.LC_CODE,A.CO_YEAR,A.VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_NAME,C.AC_NAME,C.AC_MOBILE,A.MAIN_USER ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO"
        
        sqlClient?.execute(query) { results in
            result(results)
        };
    }
    private func getSalesFilterData(result: @escaping FlutterResult,coCode:String,lcCode:String) {
        print("INside getSalesFilterData from xcode")
        sqlClient = SQLClient.sharedInstance()
        
        var query = "SELECT CO_BOOK,BOOK_NAME FROM BOOK_DATA WHERE CO_CODE = '" +
        coCode +
        "' AND LC_CODE='" +
        lcCode +
        "' AND MAIN_BOOK in ('SALES','WHSALES') AND CUR_USE='Y'"
        
        
        sqlClient?.execute(query) { results in
            result(results)
        };
        }
    private func getStockFilterGrpData(result: @escaping FlutterResult,coCode:String) {
        print("INside getStockFilterGrpData from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute( "SELECT GR_CODE,GR_NAME FROM GROUP_MAST WHERE CO_CODE='" +
                            coCode +
                            "'") { results in
            result(results)
        };
    }
    private func getStockFilterItmData(result: @escaping FlutterResult,coCode:String) {
        print("INside getStockFilterItmData from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute( "SELECT IT_NAME FROM ITEM_MAST WHERE CO_CODE ='" + coCode + "'") { results in
            result(results)
        };
    }
    private func getStockFilterPrdData(result: @escaping FlutterResult,coCode:String) {
        print("INside getStockFilterPrdData from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute( "SELECT PR_CODE,PR_NAME FROM PRODUCT_MAST WHERE CO_CODE ='" +
                            coCode +
                            "'") { results in
            result(results)
        };
    }
    private func getStockFilterTblData(result: @escaping FlutterResult,coCode:String,lcCode:String) {
        print("INside getStockFilterTblData from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute("SELECT TABLE_CODE,TABLE_NAME FROM TABLE_MAST WHERE CO_CODE='" +
                           coCode +
                           "' AND LC_CODE ='" +
                           lcCode +
                           "' ") { results in
            result(results)
        };
    }
    private func getTagEstimateData(result: @escaping FlutterResult,coCode:String,lcCode:String,year:String,tagNo:String,VchsrNo:String) {
        print("INside getStockFilterTblData from xcode")
        sqlClient = SQLClient.sharedInstance()
        var query = "";
        if(VchsrNo == ""){
        query = "SELECT B.IT_NAME,A.TAG_NO,A.IT_CODE,C.DESIGN_NO,C.ITM_SIZE,C.ITM_PCS,C.ITM_GWT,C.VCH_SRNO,B.PR_CODE,B.GR_CODE,(D.GR_RATE/10) As Rate,C.ITM_NWT AS TagNwt,C.ITM_FINE,C.LBR_AMT,C.OTH_AMT,C.LBR_PRC,C.ITM_GHT_PRC,C.ITM_GHT_WT as ITM_GHAT,C.ITM_MRP, C.LBR_RATE,C.VCH_DATE  from ((MAIN_STOCK AS A INNER JOIN BAR_DETL AS C ON A.CO_CODE = C.CO_CODE AND A.TAG_NO = C.TAG_NO AND A.VCH_SRNO = C.VCH_SRNO AND A.IT_CODE = C.IT_CODE)LEFT JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE)LEFT JOIN GROUP_MAST AS D ON B.CO_CODE = D.CO_CODE AND B.GR_CODE = D.GR_CODE WHERE A.CO_CODE = '" +
            coCode +
            "'  AND A.LC_CODE = '" +
            lcCode +
            "' AND A.CO_YEAR = '" +
            year +
            "' AND A.TAG_NO = '" +
            tagNo +
            "'  GROUP BY A.TAG_NO,A.IT_CODE,C.DESIGN_NO,C.ITM_SIZE,C.ITM_PCS,C.ITM_GWT,C.ITM_NWT,C.ITM_FINE,C.LBR_AMT,C.OTH_AMT,C.VCH_SRNO,B.PR_CODE,B.IT_NAME,B.GR_CODE,D.GR_RATE,C.LBR_PRC,C.ITM_GHT_PRC,C.ITM_GHT_WT,C.ITM_MRP, C.LBR_RATE,C.VCH_DATE HAVING SUM(CASE WHEN ITM_SIGN='+' THEN A.VCH_SRNO ELSE -A.VCH_SRNO END) > 0 ORDER BY C.VCH_DATE DESC"
        }else{
        query = "SELECT B.IT_NAME,A.TAG_NO,A.IT_CODE,C.DESIGN_NO,C.ITM_SIZE,C.ITM_PCS,C.ITM_GWT,C.VCH_SRNO,B.PR_CODE,B.GR_CODE,(D.GR_RATE/10) As Rate,C.ITM_NWT AS TagNwt,C.ITM_FINE,C.LBR_AMT,C.OTH_AMT,C.LBR_PRC,C.ITM_GHT_PRC,C.ITM_GHT_WT as ITM_GHAT,C.ITM_MRP, C.LBR_RATE  from ((MAIN_STOCK AS A INNER JOIN BAR_DETL AS C ON A.CO_CODE = C.CO_CODE AND A.TAG_NO = C.TAG_NO AND A.VCH_SRNO = C.VCH_SRNO AND A.IT_CODE = C.IT_CODE)LEFT JOIN ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.IT_CODE = B.IT_CODE)LEFT JOIN GROUP_MAST AS D ON B.CO_CODE = D.CO_CODE AND B.GR_CODE = D.GR_CODE WHERE A.CO_CODE = '" +
            coCode +
            "'  AND A.LC_CODE = '" +
            lcCode +
            "' AND A.CO_YEAR = '" +
            year +
            "' AND A.TAG_NO = '" +
            tagNo +
            "'  AND A.VCH_SRNO = '" +
            VchsrNo +
            "'  GROUP BY A.TAG_NO,A.IT_CODE,C.DESIGN_NO,C.ITM_SIZE,C.ITM_PCS,C.ITM_GWT,C.ITM_NWT,C.ITM_FINE,C.LBR_AMT,C.OTH_AMT,C.VCH_SRNO,B.PR_CODE,B.IT_NAME,B.GR_CODE,D.GR_RATE,C.LBR_PRC,C.ITM_GHT_PRC,C.ITM_GHT_WT,C.ITM_MRP, C.LBR_RATE HAVING SUM(CASE WHEN ITM_SIGN='+' THEN A.VCH_SRNO ELSE -A.VCH_SRNO END) > 0 "
        }
        print("query")
        sqlClient?.execute(query) { results in
            result(results)
        };
    }
    private func getWhSalesReport(result: @escaping FlutterResult,coCode:String,lcCode:String,year:String,fromDate:String,toDate:String) {
        print("INside getWhSalesReport from xcode")
        sqlClient = SQLClient.sharedInstance()
        sqlClient?.execute("SELECT A.CO_CODE,A.CO_YEAR,(convert(varchar(50),A.VCH_DATE,105)) as VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_SNAME,C.AC_CODE,C.AC_NAME,C.AC_MOBILE, SUM(ITM_PCS) As Pcs,Sum(A.ITM_GWT) As Gwt,SUM(A.ITM_NWT) As Nwt, (Select D.TOT_FINE_DR From RATE_CUT_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As TotDrFine, (Select D.KSR_FINE_CR From RATE_CUT_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As KasarFine, (Select D.TOT_FINE_CR From RATE_CUT_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As TotRecFine, (Select D.TOT_FINE_DR-D.KSR_FINE_CR- D.TOT_FINE_CR From RATE_CUT_DATA AS D Where A.CO_CODE = D.CO_CODE AND A.CO_YEAR = D.CO_YEAR AND A.CO_BOOK = D.CO_BOOK  AND A.VCH_NO = D.VCH_NO ) As OsFine, (Select E.DR_AMT+E.SL_LBR_AMT+E.SL_OTH_AMT+E.SL_ITM_AMT From RATE_CUT_DATA AS E Where A.CO_CODE = E.CO_CODE AND A.CO_YEAR = E.CO_YEAR AND A.CO_BOOK = E.CO_BOOK  AND A.VCH_NO = E.VCH_NO ) As NetAmt, (Select H.SL_CHQ_AMT+H.SL_CARD_AMT+SL_CASH_AMT+SL_KASAR_AMT From RATE_CUT_DATA AS H Where A.CO_CODE = H.CO_CODE AND A.CO_YEAR = H.CO_YEAR AND A.CO_BOOK = H.CO_BOOK  AND A.VCH_NO = H.VCH_NO ) As TotRcvAmt, (Select M.SL_BILL_OS From RATE_CUT_DATA AS M Where A.CO_CODE = M.CO_CODE AND A.CO_YEAR = M.CO_YEAR AND A.CO_BOOK = M.CO_BOOK  AND A.VCH_NO = M.VCH_NO ) As BillOs from (MAIN_STOCK AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE = B.CO_CODE AND A.LC_CODE = B.LC_CODE AND A.CO_BOOK = B.CO_BOOK) LEFT JOIN AC_MAST AS C ON A.CO_CODE = C.CO_CODE AND A.AC_CODE = C.AC_CODE WHERE A.CO_CODE = '" +
                           coCode +
                           "' AND A.LC_CODE = '" +
                           lcCode +
                           "' AND A.CO_YEAR = '" +
                           year +
                           "' AND A.ITM_SIGN = '-' AND A.VCH_DATE >= '" +
                           fromDate +
                           "' AND A.VCH_DATE <= '" +
                           toDate +
                           "' AND B.MAIN_BOOK IN ('WH SALES','TOUR SALES') GROUP BY A.CO_CODE,A.CO_YEAR,A.VCH_DATE,A.VCH_NO,A.CO_BOOK,B.BOOK_SNAME,C.AC_CODE,C.AC_NAME,C.AC_MOBILE ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO") { results in
            result(results)
        };
    }
    private func getSalesOrderReport(result: @escaping FlutterResult,coCode:String,lcCode:String,bookType:String,fromDate:String,toDate:String) {
        print("INside getSalesOrderReport from xcode")
        sqlClient = SQLClient.sharedInstance()
        var query = "SELECT A.AC_NAME As AC_NAME,A.MOBILE As AC_MOBILE,A.VCH_DATE AS VCH_DATE,A.VCH_NO As VCH_NO,A.TOT_AMT As TotAmt,A.ADV_AMT As AdvAmt,A.ADV_AMT-A.TOT_AMT As PandingAmt,A.DEL_DATE As DeliveryDt FROM SL_ORD_DATA AS A  WHERE A.CO_CODE = '" +
        coCode +
        "' AND A.LC_CODE = '" +
        lcCode +
        "' AND A.VCH_DATE >= '" +
        fromDate +
        "' AND A.VCH_DATE <= '" +
        toDate +
        "'"
        
        if bookType != "Select book" {
            query += "AND A.CO_BOOK = '" + bookType.split(separator: "-")[0] + "' "
        }
        
        query += "ORDER BY A.VCH_DATE DESC,A.VCH_NO"
        print(query)
        sqlClient?.execute(query) { results in
            result(results)
        };
    }
    private func getGroup(result: @escaping FlutterResult,coCode:String) {
            print("INside getGroup from xcode")
            sqlClient = SQLClient.sharedInstance()
            let query = "SELECT AC_GR,AC_GR_NAME FROM AC_GROUP WHERE CO_CODE='"+coCode+"'ORDER BY AC_GR"
            
            print(query)
            sqlClient?.execute(query) { results in
                result(results)
            };
        }
    private func getCity(result: @escaping FlutterResult,coCode:String,lcCode:String) {
            print("INside getCity from xcode")
            sqlClient = SQLClient.sharedInstance()
        let query = "Select AC_CITY FROM AC_MAST WHERE CO_CODE = '"+coCode+"' AND LC_CODE = '"+lcCode+"' AND AC_CITY<> '' GROUP BY AC_CITY"
            
            print(query)
            sqlClient?.execute(query) { results in
                result(results)
            };
        }

    private func getArea(result: @escaping FlutterResult,coCode:String,lcCode:String) {
            print("INside getArea from xcode")
            sqlClient = SQLClient.sharedInstance()
        let query = "Select AC_AREA FROM AC_MAST WHERE CO_CODE = '"+coCode+"' AND LC_CODE = '"+lcCode+"' AND AC_AREA<> '' GROUP BY AC_AREA"
            
            print(query)
            sqlClient?.execute(query) { results in
                result(results)
            };
        }
    private func getDailyRates(result: @escaping FlutterResult,coCode:String,lcCode:String,date:String) {
            print("INside getDailyRates from xcode")
            sqlClient = SQLClient.sharedInstance()
            let query = "SELECT A.GR_CODE,B.GR_NAME,A.GR_TOUCH,A.GR_RATE,A.GR_TAX_RATE,A.GR_TAX_PRC FROM RATE_MAST AS A " +
        "LEFT JOIN GROUP_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.GR_CODE = B.GR_CODE " +
        "WHERE A.CO_CODE='" + coCode + "' AND A.LC_CODE='" + lcCode + "' AND VCH_DATE = '" + date + "'\n"
            
            print(query)
            sqlClient?.execute(query) { results in
                result(results)
            };
        }
    private func getSOftType(result: @escaping FlutterResult) {
            print("INside getSOftType from xcode")
            sqlClient = SQLClient.sharedInstance()
            let query = "SELECT SUBSTRING(REF_NO,7,1) As SoftType,SUBSTRING(REF_NO,1,1) AS DemoType FROM HDD_MAST"
            print(query)
            sqlClient?.execute(query) { results in
                result(results)
            };
        }
    private func insertImage(result: @escaping FlutterResult,coCode:String,lcCode:String,tagNo:String,vchrNo:String,base64Image:String) {
            print("INside insertImage from xcode")
            sqlClient = SQLClient.sharedInstance()
            let query = "INSERT INTO TAG_IMAGE_DATA(CO_CODE,LC_CODE,TAG_NO,VCH_SRNO,IMAGE_TYPE,MOB_IMAGE) VALUES('" +
        coCode +
        "','" +
        lcCode +
        "','" +
        tagNo +
        "','" +
        vchrNo +
        "','T','" +
        base64Image +
        "')"
            print(query)
        sqlClient?.execute(query) { results in
            result(results)
        }
//            sqlClient?.execute(query) { results in
//                result(results)
//            };
        }
    private func deleteImage(result: @escaping FlutterResult,coCode:String,lcCode:String,tagNo:String,vchrNo:String) {
            print("INside deleteImage from xcode")
            sqlClient = SQLClient.sharedInstance()
            let query = "DELETE FROM TAG_IMAGE_DATA WHERE CO_CODE = '" +
        coCode +
        "' AND LC_CODE = '" +
        lcCode +
        "' AND  TAG_NO = '" +
        tagNo +
        "' AND VCH_SRNO = '" +
        vchrNo +
        "'"
            print(query)
        sqlClient?.execute(query) { results in
            result(results)
        }
//            sqlClient?.execute(query) { results in
//                result(results)
//            };
        }
    private func getCompanyDetail(result: @escaping FlutterResult,coCode:String) {
            print("INside getCompanyDetail from xcode")
            sqlClient = SQLClient.sharedInstance()
        let query = "SELECT CO_NAME,CO_ADD1,CO_ADD2,CO_ADD3,CO_CITY,CO_PIN,CO_MOBILE FROM CO_MAST WHERE CO_CODE = '"+coCode+"'"
            print(query)
        sqlClient?.execute(query) { results in
            result(results)
        }

        }
    private func getZoomingLedgerReport(result: @escaping FlutterResult,coCode:String,lcCode:String,acCode:String) {
            print("INside getZoomingLedgerReport from xcode")
            sqlClient = SQLClient.sharedInstance()
        let query = "SELECT B.BOOK_NAME,A.CO_BOOK,A.VCH_NO,A.VCH_DATE,B.MAIN_BOOK,Case When SUM(A.CR_AMT-A.DR_AMT)<0 Then abs(SUM(A.CR_AMT-A.DR_AMT))Else 0 End As DrAmt,Case When SUM(A.CR_AMT-A.DR_AMT)>0 Then abs(SUM(A.CR_AMT-A.DR_AMT))Else 0 End As CrAmt,SUM(Case When SUM(A.CR_AMT-A.DR_AMT)>0 Then abs(SUM(A.CR_AMT-A.DR_AMT))Else 0 End-Case When SUM(A.CR_AMT-A.DR_AMT)<0 Then abs(SUM(A.CR_AMT-A.DR_AMT))Else 0 End)OVER(ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO)AS BalAmt,Case When SUM(Case When A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)<0 then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end As DrGold,Case When SUM(Case When A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)>0 then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end As CrGold,SUM(Case When SUM(Case When A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)>0 then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end-Case When SUM(Case When A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)<0 then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end)OVER(ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO)as BalGold,Case WHEN SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)<0 then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end As DrSilver,Case WHEN SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)>0 then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end As CrSilver,SUM(Case When SUM(Case When A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)>0 then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end-Case When SUM(Case When A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)<0 then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end)OVER(ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO)as BalSilver FROM(AC_DATA AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE=B.CO_CODE AND A.LC_CODE=B.LC_CODE AND A.CO_BOOK=B.CO_BOOK)LEFT JOIN AC_MAST AS C ON A.CO_CODE=C.CO_CODE And A.AC_CODE=C.AC_CODE WHERE A.CO_CODE='"+coCode+"' AND A.LC_CODE='"+lcCode+"' AND A.AC_CODE='"+acCode+"' GROUP BY B.BOOK_NAME,A.CO_BOOK,A.VCH_NO,A.VCH_DATE,B.MAIN_BOOK ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO"
            print(query)
        sqlClient?.execute(query) { results in
            result(results)
        }

        }
    private func getZoomingStockReport(result: @escaping FlutterResult,coCode:String,lcCode:String,itCode:String,fromDate:String,toDate:String,selectedValue:String) {
            print("INside getZoomingStockReport from xcode")
            sqlClient = SQLClient.sharedInstance()
        let query = "SELECT A.IT_CODE,B.IT_NAME,A.CO_BOOK,A.VCH_NO,A.VCH_DATE,A.BOOK_NAME,A.TAG_NO,A.ITM_PCS,A.ITM_GWT,A.ITM_NWT,A.ITM_SIGN \nFROM MAIN_STOCK AS A LEFT JOIN ITEM_MAST AS B ON A.CO_CODE =B.CO_CODE AND A.IT_CODE =B.IT_CODE \nWHERE A.CO_CODE='"+coCode+"' AND A.LC_CODE='"+lcCode+"' AND A.IT_CODE ='"+itCode+"' AND A.VCH_DATE BETWEEN '"+fromDate+"' AND '"+toDate+"'"
        
        if selectedValue == '1' {
            query += "AND A.ITM_SIGN = '+' "
        }
        if selectedValue == '2' {
            query += "AND A.ITM_SIGN = '-' "
        }
            print(query)
        sqlClient?.execute(query) { results in
            result(results)
        }

        }
    
    private func getZoomingSalesInvoiceDetails(result: @escaping FlutterResult,coCode:String,lcCode:String,vchNo:String,coBook:String) {
            print("INside getZoomingSalesInvoiceDetails from xcode")
            sqlClient = SQLClient.sharedInstance()
        let query = "SELECT VCH_NO,VCH_DATE,MOBILE,NET_AMT,DISC_AMT,TOT_AMT,OLD_GL_AMT,CASH_AMT,KASAR_AMT,OS_ADJ_AMT,AC_NAME FROM SL_DATA WHERE CO_CODE='"+coCode+"' AND LC_CODE='"+lcCode+"' AND VCH_NO='"+vchNo+"' AND CO_BOOK='"+coBook+"'"
       
            print(query)
        sqlClient?.execute(query) { results in
            result(results)
        }

        }
    
    private func getZoomingSalesProductDetails(result: @escaping FlutterResult,coCode:String,lcCode:String,vchNo:String,coBook:String) {
            print("INside getZoomingSalesProductDetails from xcode")
            sqlClient = SQLClient.sharedInstance()
        let query = "SELECT IT_CODE,ITM_REMARK,TAG_NO,ITM_PCS,ITM_GWT,ITM_OTH_WT,ITM_NWT,ITM_RATE,ITM_AMT,LBR_PRC,LBR_RATE,LBR_AMT,OTH_AMT,ITM_MRP,TOT_AMT FROM SL_DETL WHERE CO_CODE = '"+coCode+"' AND LC_CODE = '"+lcCode+"' AND CO_BOOK = '"+coBook+"' AND VCH_NO = '"+vchNo+"' ORDER BY SR_NO"
       
            print(query)
        sqlClient?.execute(query) { results in
            result(results)
        }

        }
    func error(_ error: String!, code: Int32, severity: Int32) {
        print("\(error!) \(code) \(severity)")
    }
}
