import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

import 'mySql_services.dart';

class StockzoomingReport extends StatefulWidget {
  final String ItCOode;
  final String fromDate;
  final String toDate;
  const StockzoomingReport(
      {super.key,
      required this.ItCOode,
      required this.fromDate,
      required this.toDate});

  @override
  State<StockzoomingReport> createState() => _StockzoomingreportState();
}

class _StockzoomingreportState extends State<StockzoomingReport> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);

  Color get _cta => _brand;

  final sqlConnection = SqlConnection.getInstance();
  late LoadingProvider loadingProvider;
  String co_code = "";
  String year = "";
  String lc_code = "";
  int _selectedValue = 0;
  List<dynamic> stockReportZooming = [];

  @override
  void initState() {
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    year =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_year;
    lc_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .lc_code;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getStockZoomingReport();
    });
  }

  void getStockZoomingReport() async {
    loadingProvider.startLoading();

    try {
      if (Platform.isAndroid) {
        String query =
            "SELECT A.IT_CODE,B.IT_NAME,A.CO_BOOK,A.VCH_NO,A.VCH_DATE,A.BOOK_NAME,A.TAG_NO,A.ITM_PCS,A.ITM_GWT,A.ITM_NWT,A.ITM_SIGN \nFROM MAIN_STOCK AS A LEFT JOIN ITEM_MAST AS B ON A.CO_CODE =B.CO_CODE AND A.IT_CODE =B.IT_CODE \nWHERE A.CO_CODE='$co_code' AND A.LC_CODE='$lc_code' AND A.IT_CODE ='${widget.ItCOode}' AND A.VCH_DATE BETWEEN '${widget.fromDate}' AND '${widget.toDate}'";

        if (_selectedValue == 1) {
          query += "AND A.ITM_SIGN = '+' ";
        }
        if (_selectedValue == 2) {
          query += "AND A.ITM_SIGN = '-' ";
        }

        log("STOCK/ZOOMING QUERY ${query}");
        dynamic result = await sqlConnection.queryDatabase(query);
        log("STOCK/ZOOMING result ${result}");
        stockReportZooming = jsonDecode(result);
        setState(() {});
      } else {
        dynamic result = await MySQLService().getZoomingStockReport(
            coCode: co_code,
            lcCode: lc_code,
            itCode: year,
            fromDate: widget.fromDate,
            toDate: widget.toDate,
            selectedValue: _selectedValue.toString());
        stockReportZooming = result[0];
        setState(() {});
      }
    } catch (e) {
      log('Error fetching stock zooming report: $e');
      stockReportZooming = [];
      if (mounted) {
        showAppToast(context, "Could not load stock detail. Please try again.");
      }
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  Widget _kvRow(String label, String value,
      {Color? valueColor, bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: emphasize ? 13 : 12,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                height: 1.35,
              ),
            ),
          ),
          Text(
            ': ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _border,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: emphasize ? 18 : 13,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
                height: 1.35,
                letterSpacing: emphasize ? -0.35 : -0.15,
                color: valueColor ?? _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _radioOption(int radioValue, String title) {
    final selected = _selectedValue == radioValue;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: [
                  _cta.withValues(alpha: 0.2),
                  _cta.withValues(alpha: 0.06),
                ],
              )
            : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? _cta.withValues(alpha: 0.42)
              : _border.withValues(alpha: 0.85),
          width: selected ? 1.25 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: _cta.withValues(alpha: 0.1),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<int>(
            value: radioValue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? _cta : _textPrimary.withValues(alpha: 0.88),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radioTheme = Theme.of(context).copyWith(
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _cta;
          return _border;
        }),
      ),
    );

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textPrimary,
        automaticallyImplyLeading: false,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.white.withValues(alpha: 0.96),
                _pageBg,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _cta,
              size: 22,
            ),
          ),
        ),
        title: Text(
          'Item in / out',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            color: _cta,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: _border.withValues(alpha: 0.65),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFEEF2F7),
                    _pageBg,
                    _pageBg,
                  ],
                  stops: const [0.0, 0.22, 1.0],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Theme(
                  data: radioTheme,
                  child: RadioGroup<int>(
                    groupValue: _selectedValue,
                    onChanged: (int? value) {
                      if (value == null) return;
                      setState(() => _selectedValue = value);
                      getStockZoomingReport();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Color.lerp(Colors.white, _pageBg, 0.15)!,
                          ],
                        ),
                        border: Border.all(
                          color: _cta.withValues(alpha: 0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _cta.withValues(alpha: 0.08),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _radioOption(0, 'ALL'),
                          _radioOption(1, 'In Stock'),
                          _radioOption(2, 'Out Stock'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Consumer<LoadingProvider>(
                  builder: (context, loading, _) {
                    if (loading.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(color: _cta),
                      );
                    }
                    if (stockReportZooming.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_outlined,
                              size: 56,
                              color: _textSecondary.withValues(alpha: 0.45),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No data found',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      itemCount: stockReportZooming.length,
                      itemBuilder: (context, index) {
                        final row = stockReportZooming[index];
                        final signOut = row['ITM_SIGN'] == '-';
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                index == stockReportZooming.length - 1 ? 6 : 12,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _cta.withValues(alpha: 0.42),
                                  _cta.withValues(alpha: 0.08),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _cta.withValues(alpha: 0.12),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(1.25),
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.75),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x060F172A),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Name : ',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                color: _cta,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '${row['IT_NAME']}',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  letterSpacing: -0.25,
                                                  color: _textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: signOut
                                              ? _danger.withValues(alpha: 0.1)
                                              : _success.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          signOut
                                              ? Icons.arrow_downward_rounded
                                              : Icons.arrow_upward_rounded,
                                          color: signOut ? _danger : _success,
                                          size: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _border.withValues(alpha: 0.65),
                                  ),
                                  const SizedBox(height: 12),
                                  _kvRow(
                                    'Vch No',
                                    '${row['VCH_NO']}',
                                  ),
                                  _kvRow(
                                    'Vch Date',
                                    '${row['VCH_DATE']}',
                                  ),
                                  _kvRow(
                                    'Book Name',
                                    '${row['BOOK_NAME']}',
                                  ),
                                  _kvRow(
                                    'Tag No',
                                    '${row['TAG_NO']}',
                                  ),
                                  _kvRow(
                                    'Item Pcs',
                                    row['ITM_PCS'].toString(),
                                  ),
                                  _kvRow(
                                    'Gross Weight',
                                    double.parse(row['ITM_GWT'].toString())
                                        .toStringAsFixed(3),
                                  ),
                                  _kvRow(
                                    'Net Weight',
                                    double.parse(row['ITM_NWT'].toString())
                                        .toStringAsFixed(3),
                                  ),
                                  _kvRow(
                                    'Sign',
                                    '${row['ITM_SIGN']}',
                                    valueColor: signOut ? _danger : _success,
                                    emphasize: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
