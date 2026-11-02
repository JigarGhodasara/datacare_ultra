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
  String companyName = "";

  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  DateTime? fromDate;
  DateTime? toDate;

  // Design tokens
  static const Color _primary = Color(0xFF006EB7);
  static const Color _primaryDark = Color(0xFF00456F);
  static const Color _pageBg = Color(0xFFF3F6FA);
  static const Color _border = Color(0xFFE4EAF1);
  static const Color _textPrimary = Color(0xFF1E2A36);
  static const Color _textSecondary = Color(0xFF6B7A8A);
  static const Color _whatsapp = Color(0xFF25D366);
  static const Color _call = Color(0xFF2E7D32);
  static const Color _sms = Color(0xFFEF6C00);

  @override
  void initState() {
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    final companyProvider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    co_code = companyProvider.co_code;
    lc_code = companyProvider.lc_code;
    companyName = companyProvider.co_name.trim().isNotEmpty
        ? companyProvider.co_name.trim()
        : companyProvider.CoSname.trim();

    final today = DateTime.now();
    fromDate = today;
    toDate = today;
    fromDateController.text = DateFormat("dd/MM/yyyy").format(today);
    toDateController.text = DateFormat("dd/MM/yyyy").format(today);

    getReminderData(DateFormat("MM/dd/yyyy").format(fromDate!),
        DateFormat("MM/dd/yyyy").format(toDate!), co_code, lc_code);
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

  Future<void> pickDate({required bool isFromDate}) async {
    DateTime initialDate = isFromDate ? fromDate! : toDate!;
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
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

      getReminderData(
          DateFormat("MM/dd/yyyy")
              .format(DateFormat("dd/MM/yyyy").parse(fromDateController.text)),
          DateFormat("MM/dd/yyyy")
              .format(DateFormat("dd/MM/yyyy").parse(toDateController.text)),
          co_code,
          lc_code);
    }
  }

  Future<void> getReminderData(
      String fromDate, String toDate, String coCode, String lcCode) async {
    loadingProvider.startLoading();
    reminderData.clear();
    try {
      if (Platform.isAndroid) {
        String baseQuery =
            "SELECT A.*, B.AC_MOBILE FROM REM_DATA AS A LEFT JOIN AC_MAST AS B ON A.CO_CODE = B.CO_CODE AND A.AC_CODE = B.AC_CODE "
            "WHERE A.CO_CODE = '$coCode' AND A.LC_CODE = '$lcCode' "
            "AND A.REM_DATE >= '$fromDate' "
            "AND A.REM_DATE <= '$toDate'";
        dynamic result = await sqlConnection.queryDatabase(baseQuery);
        reminderData.addAll(jsonDecode(result));
      } else {
        try {
          dynamic result2 = await MySQLService()
              .getReminder(coCode, lcCode, fromDate, toDate);
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
    } catch (e) {
      log('Error fetching reminder data: $e');
      if (mounted) _toast("Could not load reminders. Please try again.");
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      automaticallyImplyLeading: false,
      shape: const Border(
        bottom: BorderSide(color: _border, width: 1),
      ),
      leadingWidth: 56,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _primary, size: 22),
      ),
      title: Text(
        "Reminder",
        style: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _primary,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Date range selector
  // ---------------------------------------------------------------------------
  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _dateField(
              label: "From Date",
              controller: fromDateController,
              onTap: () => pickDate(isFromDate: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dateField(
              label: "To Date",
              controller: toDateController,
              onTap: () => pickDate(isFromDate: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: _pageBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: _primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.text,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: _textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Reminder list / states
  // ---------------------------------------------------------------------------
  Widget _buildBody() {
    return Consumer<LoadingProvider>(
      builder: (context, lp, _) {
        if (lp.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }
        if (reminderData.isEmpty) {
          return _buildEmptyState();
        }
        return _buildReminderList();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_rounded,
                size: 44, color: _primary),
          ),
          const SizedBox(height: 18),
          Text(
            "No reminders found",
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Try adjusting the date range above",
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: reminderData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = reminderData[index] as Map<String, dynamic>;
        return _reminderCard(data);
      },
    );
  }

  Widget _reminderCard(Map<String, dynamic> data) {
    final String name = (data["AC_NAME"] ?? "").toString();
    final String mobile = (data["AC_MOBILE"] ?? "").toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1A2F).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _initials(name),
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.nunito(
                      color: _textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                _infoRow(Icons.receipt_long_rounded, "Vch No",
                    (data["VCH_NO"] ?? "").toString()),
                _infoRow(Icons.phone_rounded, "Mobile",
                    mobile.isEmpty ? "-" : mobile),
                _infoRow(Icons.menu_book_rounded, "Book Name",
                    (data["BOOK_NAME"] ?? "").toString()),
                _infoRow(Icons.event_rounded, "Reminder Date",
                    (data["REM_DATE"] ?? "").toString(),
                    isLast: true),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(AppImage.whatsapp, _whatsapp,
                    () => _sendWhatsApp(mobile, data)),
                _actionButton(
                    AppImage.telephone, _call, () => _makeCall(mobile)),
                _actionButton(
                    AppImage.chat, _sms, () => _sendSms(mobile, data)),
                _actionButton(
                    AppImage.share, _primary, () => _shareMessage(data)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              textAlign: TextAlign.right,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String asset, Color tint, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Image.asset(asset, height: 22, width: 22),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // ---------------------------------------------------------------------------
  // Messaging / actions
  // ---------------------------------------------------------------------------
  String _reminderMessage(Map<String, dynamic> data) {
    final name = (data["AC_NAME"] ?? "").toString().trim();
    final vch = (data["VCH_NO"] ?? "").toString().trim();
    final book = (data["BOOK_NAME"] ?? "").toString().trim();
    final date = (data["REM_DATE"] ?? "").toString().trim();

    final b = StringBuffer();
    b.writeln("Dear ${name.isEmpty ? "Customer" : name},");
    b.writeln();
    b.write("This is a gentle reminder");
    if (companyName.isNotEmpty) b.write(" from $companyName");
    b.writeln(".");
    if (vch.isNotEmpty) b.writeln("Voucher No: $vch");
    if (book.isNotEmpty) b.writeln("Book: $book");
    if (date.isNotEmpty) b.writeln("Reminder Date: $date");
    b.writeln();
    b.writeln("Kindly contact us for further details.");
    b.write("Thank you.");
    return b.toString();
  }

  String _dialNumber(String mobile) {
    final cleaned = mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('91') && cleaned.length > 10) return '+$cleaned';
    return '+91$cleaned';
  }

  bool _ensureMobile(String mobile) {
    if (mobile.replaceAll(RegExp(r'[^0-9]'), '').isEmpty) {
      _toast("No mobile number available for this reminder");
      return false;
    }
    return true;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendWhatsApp(String mobile, Map<String, dynamic> data) async {
    if (!_ensureMobile(mobile)) return;
    final link = WhatsAppUnilink(
      phoneNumber: _dialNumber(mobile),
      text: _reminderMessage(data),
    );
    final ok =
        await launchUrlString('$link', mode: LaunchMode.externalApplication);
    if (!ok) _toast("Could not open WhatsApp");
  }

  Future<void> _makeCall(String mobile) async {
    if (!_ensureMobile(mobile)) return;
    final ok = await launchUrlString("tel:${_dialNumber(mobile)}");
    if (!ok) _toast("Could not start the call");
  }

  Future<void> _sendSms(String mobile, Map<String, dynamic> data) async {
    if (!_ensureMobile(mobile)) return;
    final body = Uri.encodeComponent(_reminderMessage(data));
    final ok = await launchUrlString('sms:${_dialNumber(mobile)}?body=$body');
    if (!ok) _toast("Could not open Messages");
  }

  Future<void> _shareMessage(Map<String, dynamic> data) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _reminderMessage(data),
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
