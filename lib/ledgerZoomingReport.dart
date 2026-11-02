import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/voucher_chip.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

class Ledgerzoomingreport extends StatefulWidget {
  final String name;
  final String acCode;
  const Ledgerzoomingreport(
      {super.key, required this.name, required this.acCode});

  @override
  State<Ledgerzoomingreport> createState() => _LedgerzoomingreportState();
}

class _LedgerzoomingreportState extends State<Ledgerzoomingreport> {
  static const Color _brand = Color(0xFF006EB7);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);

  final sqlConnection = SqlConnection.getInstance();
  late LoadingProvider loadingProvider;
  List<dynamic> ledgerZoomingReport = [];
  String co_code = "";
  String lc_code = "";

  @override
  void initState() {
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    co_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .co_code;
    lc_code =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false)
            .lc_code;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getLedegerZoomingReport();
    });
  }

  getLedegerZoomingReport() async {
    loadingProvider.startLoading();
    try {
      if (Platform.isAndroid) {
        String query =
            "SELECT B.BOOK_NAME,A.CO_BOOK,A.VCH_NO,A.VCH_DATE,B.MAIN_BOOK,Case When SUM(A.CR_AMT-A.DR_AMT)<0 Then abs(SUM(A.CR_AMT-A.DR_AMT))Else 0 End As DrAmt,Case When SUM(A.CR_AMT-A.DR_AMT)>0 Then abs(SUM(A.CR_AMT-A.DR_AMT))Else 0 End As CrAmt,SUM(Case When SUM(A.CR_AMT-A.DR_AMT)>0 Then abs(SUM(A.CR_AMT-A.DR_AMT))Else 0 End-Case When SUM(A.CR_AMT-A.DR_AMT)<0 Then abs(SUM(A.CR_AMT-A.DR_AMT))Else 0 End)OVER(ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO)AS BalAmt,Case When SUM(Case When A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)<0 then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end As DrGold,Case When SUM(Case When A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)>0 then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end As CrGold,SUM(Case When SUM(Case When A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)>0 then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end-Case When SUM(Case When A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)<0 then abs(SUM(CASE WHEN A.IT_TYPE='G' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end)OVER(ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO)as BalGold,Case WHEN SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)<0 then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end As DrSilver,Case WHEN SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)>0 then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end As CrSilver,SUM(Case When SUM(Case When A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)>0 then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end-Case When SUM(Case When A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END)<0 then abs(SUM(CASE WHEN A.IT_TYPE='S' THEN(CASE WHEN A.SIGN='+' THEN A.FINE_WT ELSE-A.FINE_WT END)ELSE 0 END))else 0 end)OVER(ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO)as BalSilver FROM(AC_DATA AS A LEFT JOIN BOOK_DATA AS B ON A.CO_CODE=B.CO_CODE AND A.LC_CODE=B.LC_CODE AND A.CO_BOOK=B.CO_BOOK)LEFT JOIN AC_MAST AS C ON A.CO_CODE=C.CO_CODE And A.AC_CODE=C.AC_CODE WHERE A.CO_CODE='$co_code' AND A.LC_CODE='$lc_code' AND A.AC_CODE='${widget.acCode}' GROUP BY B.BOOK_NAME,A.CO_BOOK,A.VCH_NO,A.VCH_DATE,B.MAIN_BOOK ORDER BY A.VCH_DATE,A.CO_BOOK,A.VCH_NO";

        log(query);
        dynamic result = await sqlConnection.queryDatabase(query);
        log("Result $result");
        ledgerZoomingReport.addAll(jsonDecode(result));
      } else {
        dynamic grp = await MySQLService()
            .getZoomingLedgerReport(co_code, lc_code, widget.acCode);
        ledgerZoomingReport.addAll(grp[0]);
      }
    } catch (e) {
      log('Error fetching ledger zooming report: $e');
      if (mounted) {
        showAppToast(
            context, "Could not load ledger detail. Please try again.");
      }
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  String _fmt(dynamic value, int decimals) {
    final parsed = double.tryParse('${value ?? ''}');
    if (parsed == null) return '${value ?? '-'}';
    return parsed.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _brand,
              size: 22,
            ),
          ),
        ),
        title: Text(
          widget.name,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            color: _brand,
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
      body: Consumer<LoadingProvider>(
        builder: (context, loading, _) {
          if (loading.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _brand),
            );
          }
          if (ledgerZoomingReport.isEmpty) {
            return _emptyState();
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            itemCount: ledgerZoomingReport.length,
            itemBuilder: (context, index) {
              final data = ledgerZoomingReport[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == ledgerZoomingReport.length - 1 ? 0 : 12,
                ),
                child: _transactionCard(data),
              );
            },
          );
        },
      ),
    );
  }

  Widget _transactionCard(dynamic data) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _brand.withValues(alpha: 0.4),
            _brand.withValues(alpha: 0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.25),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['BOOK_NAME'] ?? '-'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: _textPrimary,
                        ),
                      ),
                      if (VoucherChip.numberOf(data).isNotEmpty) ...[
                        const SizedBox(height: 7),
                        VoucherChip(vchNo: VoucherChip.numberOf(data)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${data['VCH_DATE'] ?? '-'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _brand,
                    ),
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
            _metricRow(
              'Amount',
              cr: _fmt(data['CrAmt'], 2),
              dr: _fmt(data['DrAmt'], 2),
              balance: _fmt(data['BalAmt'], 2),
            ),
            const SizedBox(height: 10),
            _metricRow(
              'Gold',
              cr: _fmt(data['CrGold'], 3),
              dr: _fmt(data['DrGold'], 3),
              balance: _fmt(data['BalGold'], 3),
            ),
            const SizedBox(height: 10),
            _metricRow(
              'Silver',
              cr: _fmt(data['CrSilver'], 3),
              dr: _fmt(data['DrSilver'], 3),
              balance: _fmt(data['BalSilver'], 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label,
      {required String cr, required String dr, required String balance}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ),
        Expanded(
          child: _miniStat('Cr', cr, _success),
        ),
        Expanded(
          child: _miniStat('Dr', dr, _danger),
        ),
        Expanded(
          child: _miniStat('Bal', balance, _brand),
        ),
      ],
    );
  }

  Widget _miniStat(String caption, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _brand.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 46,
              color: _brand.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This account has no ledger entries',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
