import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  static final sqlConnection = SqlConnection.getInstance();
   String co_code = "";
   String lc_code = "";
  static List<dynamic> reminderData = [];
  List<String> bookList = [];
  String? selectedBook;

 static late LoadingProvider loadingProvider;

  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    final companyProvider =
    Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    co_code = companyProvider.co_code;
    lc_code = companyProvider.lc_code;

    final today = DateTime.now();
    fromDate = today;
    toDate = today;
    fromDateController.text = DateFormat("dd/MM/yyyy").format(today);
    toDateController.text = DateFormat("dd/MM/yyyy").format(today);

    getReminderData(DateFormat("MM/dd/yyyy").format(fromDate!),DateFormat("MM/dd/yyyy").format(toDate!),co_code,lc_code);
  }

  Future<void> pickDate({required bool isFromDate}) async {
    DateTime initialDate = isFromDate ? fromDate! : toDate!;
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
          fromDateController.text = DateFormat("dd/MM/yyyy").format(picked);
        } else {
          toDate = picked;
          toDateController.text = DateFormat("dd/MM/yyyy").format(picked);
        }
      });

      getReminderData(DateFormat("MM/dd/yyyy").format(DateFormat("dd/MM/yyyy").parse(fromDateController.text)),DateFormat("MM/dd/yyyy").format(DateFormat("dd/MM/yyyy").parse(toDateController.text)),co_code,lc_code);
    }
  }

  Future<void> getReminderData(String fromDate,String toDate,String coCode,String lcCode) async {
    loadingProvider.startLoading();
    // setState(() {
      reminderData.clear();
    // });
    if(Platform.isAndroid){
      String baseQuery =
          "SELECT A.*, B.AC_MOBILE FROM REM_DATA AS A LEFT JOIN AC_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.AC_CODE = B.AC_CODE "
          "WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' "
          "AND A.REM_DATE >= '$fromDate' "
          "AND A.REM_DATE <= '$toDate'";
      dynamic result = await sqlConnection.queryDatabase(baseQuery);
      reminderData.addAll(jsonDecode(result));
    }else {
      try {
        dynamic result2 = await MySQLService().getReminder(coCode, lcCode, fromDate, toDate);
        final rawList = result2[0] as List;
        final convertedList = rawList.map<Map<String, dynamic>>((item) {
          return Map<String, dynamic>.from(item as Map);
        }).toList();
        reminderData.addAll(convertedList);
      } catch (e) {
        log('Error fetching iOS reminder data: $e');
        rethrow;
      }

    }
    loadingProvider.stopLoading();
    setState(() {});
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "From To Date",
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF006EB7),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => pickDate(isFromDate: true),  
                  child: AbsorbPointer(
                    child: TextField(
                      controller: fromDateController,
                      textAlign: TextAlign.center,
                      decoration: _dateInputDecoration(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => pickDate(isFromDate: false),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: toDateController,
                      textAlign: TextAlign.center,
                      decoration: _dateInputDecoration(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _dateInputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      suffixIcon: const Icon(Icons.arrow_drop_down),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF006EB7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF006EB7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF006EB7), width: 2),
      ),
    );
  }


  Widget _buildReminderList() {
    return ListView.builder(
      itemCount: reminderData.length,
      itemBuilder: (context, index) {
        final data = reminderData[index];
        return Padding(
          padding: EdgeInsets.only(
              top: 15, left: 15, right: 15, bottom: index == reminderData.length - 1 ? 15 : 0),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  spreadRadius: -10,
                  offset: Offset(2, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data["AC_NAME"].toString(),
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF006EB7),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 2, color: Colors.grey),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLabelColumn(),
                    const SizedBox(width: 10),
                    _buildColonColumn(),
                    const SizedBox(width: 8),
                    _buildValueColumn(data),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 2, color: Colors.grey),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionIcon(AppImage.whatsapp, () async {
                      final link = WhatsAppUnilink(
                        phoneNumber: '+91${data["AC_MOBILE"].toString()}',
                        text: "Hello",
                      );
                      await launchUrlString('$link');
                    }),
                    _actionIcon(AppImage.telephone, () {
                      launchUrlString("tel:+91${data["AC_MOBILE"].toString()}");
                    }),
                    _actionIcon(AppImage.chat, () {
                      launchUrlString(
                          'sms:+91${data["AC_MOBILE"].toString()}?body=Hello');
                    }),
                    _actionIcon(AppImage.share, () {
                      Share.share('Hello');
                    }),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabelColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoLabel("Vch No"),
        _infoLabel("Mobile"),
        _infoLabel("Book Name"),
        _infoLabel("Reminder Date"),
      ],
    );
  }

  Widget _buildColonColumn() {
    return Column(
      children: List.generate(4, (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.5),
          child: Text(":", style: _infoStyle()),
        );
      }),
    );
  }

  Widget _buildValueColumn(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoValue(data["VCH_NO"].toString()),
        _infoValue(data["AC_MOBILE"]?? "".toString() ),
        _infoValue(data["BOOK_NAME"].toString()),
        _infoValue(data["REM_DATE"].toString()),
      ],
    );
  }

  Widget _infoLabel(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3.5),
    child: Text(text,
        style: GoogleFonts.nunito(
            color: const Color(0xFF006EB7),
            fontWeight: FontWeight.w500,
            fontSize: 15)),
  );

  Widget _infoValue(String? text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3.5),
    child: Text(text ?? "", style: _infoStyle()),
  );

  TextStyle _infoStyle() =>
      GoogleFonts.nunito(fontWeight: FontWeight.w500, fontSize: 15);

  Widget _actionIcon(String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(asset, scale: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Reminder",
          style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF006EB7)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.keyboard_arrow_left_rounded,
            color: Color(0xFF006EB7),
            size: 45,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(child: _buildReminderList()),
        ],
      ),
    );
  }
}
