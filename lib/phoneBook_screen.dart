import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sql_connection/sql_connection.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

class PhonebookScreen extends StatefulWidget {
  const PhonebookScreen({Key? key}) : super(key: key);

  @override
  State<PhonebookScreen> createState() => _PhonebookScreenState();
}

class _PhonebookScreenState extends State<PhonebookScreen> {
  final sqlConnection = SqlConnection.getInstance();
  List<dynamic> phoneBook = [];
  List<dynamic> searchPhoneBook = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String companyName = "";

  // Design tokens (consistent with the app's blue theme)
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
    getPhoneBookData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void getPhoneBookData() async {
    final provider =
        Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false);
    String co_code = provider.co_code;
    companyName = provider.co_name.trim().isNotEmpty
        ? provider.co_name.trim()
        : provider.CoSname.trim();

    try {
      if (Platform.isAndroid) {
        String RsQry =
            "SELECT AC_CODE,AC_NAME,AC_CITY,AC_MOBILE,AC_AREA,AC_EMAIL,AC_ADD1,AC_ADD2,AC_ADD3 FROM AC_MAST WHERE CO_CODE = '" +
                co_code +
                "' AND AC_GR IN ('00','01','04','05','10','15','20') AND AC_MOBILE IS NOT NULL AND AC_MOBILE != '' ORDER BY AC_NAME";
        dynamic result = await sqlConnection.queryDatabase(RsQry);
        phoneBook = jsonDecode(result);
      } else {
        dynamic result = await MySQLService().getPhoneBookData(co_code);
        phoneBook = result[0];
      }
      searchPhoneBook = List.from(phoneBook);
    } catch (e, s) {
      log('getPhoneBookData failed', error: e, stackTrace: s);
    }
    _isLoading = false;
    if (mounted) setState(() {});
  }

  void _onSearch(String value) {
    final q = value.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        searchPhoneBook = List.from(phoneBook);
      } else {
        searchPhoneBook = phoneBook.where((e) {
          final name = (e["AC_NAME"] ?? "").toString().toLowerCase();
          final mobile = (e["AC_MOBILE"] ?? "").toString().toLowerCase();
          return name.contains(q) || mobile.contains(q);
        }).toList();
      }
    });
  }

  String _str(Map data, String key) => (data[key] ?? "").toString().trim();

  // ---------------------------------------------------------------------------
  // App bar & search
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      automaticallyImplyLeading: false,
      shape: const Border(bottom: BorderSide(color: _border, width: 1)),
      leadingWidth: 56,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _primary, size: 22),
      ),
      title: Text(
        "Phone Book",
        style: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _primary,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        cursorColor: _primary,
        onChanged: _onSearch,
        style: GoogleFonts.nunito(
            fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary),
        decoration: InputDecoration(
          hintText: "Search by name or mobile",
          hintStyle: GoogleFonts.nunito(color: _textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _primary),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: _textSecondary, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch("");
                  },
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body / states
  // ---------------------------------------------------------------------------
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (searchPhoneBook.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: searchPhoneBook.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _contactCard(searchPhoneBook[index] as Map),
    );
  }

  Widget _buildEmptyState() {
    final searching = _searchController.text.trim().isNotEmpty;
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
            child: Icon(
                searching ? Icons.search_off_rounded : Icons.contacts_rounded,
                size: 44,
                color: _primary),
          ),
          const SizedBox(height: 18),
          Text(
            searching ? "No matching contacts" : "No contacts found",
            style: GoogleFonts.nunito(
                fontSize: 17, fontWeight: FontWeight.w800, color: _textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? "Try a different name or number"
                : "Contacts will appear here",
            style: GoogleFonts.nunito(fontSize: 13.5, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(Map data) {
    final String name = _str(data, "AC_NAME");
    final String mobile = _str(data, "AC_MOBILE");
    final String address = [
      _str(data, "AC_ADD1"),
      _str(data, "AC_ADD2"),
      _str(data, "AC_ADD3"),
    ].where((e) => e.isNotEmpty).join(", ");
    final String area = _str(data, "AC_AREA");
    final String city = _str(data, "AC_CITY");
    final String email = _str(data, "AC_EMAIL");

    final entries = <List<dynamic>>[
      [Icons.phone_rounded, "Mobile", mobile.isEmpty ? "-" : mobile],
      if (address.isNotEmpty) [Icons.location_on_rounded, "Address", address],
      if (area.isNotEmpty) [Icons.map_rounded, "Area", area],
      if (city.isNotEmpty) [Icons.location_city_rounded, "City", city],
      if (email.isNotEmpty) [Icons.email_rounded, "Email", email],
    ];

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
                    name.isEmpty ? "-" : name,
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
                for (int i = 0; i < entries.length; i++)
                  _infoRow(
                    entries[i][0] as IconData,
                    entries[i][1] as String,
                    entries[i][2] as String,
                    isLast: i == entries.length - 1,
                  ),
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
                    AppImage.share, _primary, () => _shareContact(data)),
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
            width: 72,
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
          child: Center(child: Image.asset(asset, height: 22, width: 22)),
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
  String _greeting(Map data) {
    final name = _str(data, "AC_NAME");
    final b = StringBuffer();
    b.writeln("Hello${name.isEmpty ? "" : " $name"},");
    b.writeln();
    b.write("Greetings");
    if (companyName.isNotEmpty) b.write(" from $companyName");
    b.writeln(".");
    b.writeln();
    b.write("Thank you.");
    return b.toString();
  }

  String _contactShareText(Map data) {
    final b = StringBuffer();
    final name = _str(data, "AC_NAME");
    if (name.isNotEmpty) b.writeln(name);
    final mobile = _str(data, "AC_MOBILE");
    if (mobile.isNotEmpty) b.writeln("Mobile: $mobile");
    final address = [
      _str(data, "AC_ADD1"),
      _str(data, "AC_ADD2"),
      _str(data, "AC_ADD3"),
    ].where((e) => e.isNotEmpty).join(", ");
    if (address.isNotEmpty) b.writeln("Address: $address");
    final area = _str(data, "AC_AREA");
    if (area.isNotEmpty) b.writeln("Area: $area");
    final city = _str(data, "AC_CITY");
    if (city.isNotEmpty) b.writeln("City: $city");
    final email = _str(data, "AC_EMAIL");
    if (email.isNotEmpty) b.writeln("Email: $email");
    return b.toString().trim();
  }

  String _dialNumber(String mobile) {
    final cleaned = mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('91') && cleaned.length > 10) return '+$cleaned';
    return '+91$cleaned';
  }

  bool _ensureMobile(String mobile) {
    if (mobile.replaceAll(RegExp(r'[^0-9]'), '').isEmpty) {
      _toast("No mobile number available for this contact");
      return false;
    }
    return true;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendWhatsApp(String mobile, Map data) async {
    if (!_ensureMobile(mobile)) return;
    final link = WhatsAppUnilink(
      phoneNumber: _dialNumber(mobile),
      text: _greeting(data),
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

  Future<void> _sendSms(String mobile, Map data) async {
    if (!_ensureMobile(mobile)) return;
    final body = Uri.encodeComponent(_greeting(data));
    final ok = await launchUrlString('sms:${_dialNumber(mobile)}?body=$body');
    if (!ok) _toast("Could not open Messages");
  }

  Future<void> _shareContact(Map data) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _contactShareText(data),
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
          _buildSearchField(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
