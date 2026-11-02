import 'dart:math' as math;

import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/utils/keys.dart';
import 'package:DataCareUltra/utils/preffrance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';

/// Server connection — same validation & save behaviour as legacy; production-grade form UX.
class SettingScreen extends StatefulWidget {
  final bool isFromSplash;

  const SettingScreen({Key? key, required this.isFromSplash}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController userNameController =
      TextEditingController(text: 'sa');
  final TextEditingController passwordController =
      TextEditingController(text: 'datacare@123');
  final TextEditingController databaseController =
      TextEditingController(text: 'NextMain');
  bool isShow = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Single brand anchor — icons, focus, header, and CTA derive from this family.
  static const Color _brand = Color(0xFF1565C0);
  static const Color _brandDark = Color(0xFF0D47A1);
  static const Color _sheetSurface = Color(0xFFF8FAFC);
  static const Color _inputFill = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('SettingScreen: production form layout');
    }
    getDataFromStorage();
  }

  @override
  void dispose() {
    ipController.dispose();
    userNameController.dispose();
    passwordController.dispose();
    databaseController.dispose();
    super.dispose();
  }

  Color get _ctaFill => AppColor.PRIMARY_COLOR ?? _brand;

  /// Standard outline field: label above, compact leading icon, hint + value area never squeezed.
  Widget _labeledField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String iconAsset,
    bool obscure = false,
    TextInputAction textInputAction = TextInputAction.next,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    final radius = BorderRadius.circular(12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          textInputAction: textInputAction,
          scrollPadding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 80,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 120,
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: 1,
                child: Image.asset(
                  iconAsset,
                  width: 22,
                  height: 22,
                  color: _brand,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              maxWidth: 44,
              minHeight: 44,
              maxHeight: 44,
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: _inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: _border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: _border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: _brand, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _onSubmit() async {
    await HapticFeedback.lightImpact();
    if (ipController.text != '' &&
        userNameController.text != '' &&
        passwordController.text != '' &&
        databaseController.text != '') {
      Preffrance().setString(Keys.HOST, ipController.text);
      Preffrance().setString(Keys.USERNAME, userNameController.text);
      Preffrance().setString(Keys.PASSWORD, passwordController.text);
      Preffrance().setString(Keys.DATABASE, databaseController.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      print("${await Preffrance().getString(Keys.HOST)}");
      print("${await Preffrance().getString(Keys.USERNAME)}");
      print("${await Preffrance().getString(Keys.PASSWORD)}");
      print("${await Preffrance().getString(Keys.DATABASE)}");
    } else {
      if (!mounted) return;
      await HapticFeedback.selectionClick();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            'Please enter all details.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final padH = w < 360 ? 18.0 : math.min(28.0, w * 0.065);
    final maxW = math.min(w - 2 * padH, 440.0);
    // Slightly smaller logo on short screens so form fits without scaling as much.
    final logoDim = (w * 0.18).clamp(64.0, h < 640 ? 80.0 : 92.0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _brandDark,
      body: Column(
        children: [
          _buildHeader(w),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _sheetSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padH, 10, padH, 0),
                        // Top-aligned scroll: avoids a “floating” sheet when the keyboard opens.
                        // Scaffold already resizes above the keyboard — do not add full viewInsets
                        // again as bottom padding (that created huge empty space / wrong layout).
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: SingleChildScrollView(
                            clipBehavior: Clip.hardEdge,
                            physics: const ClampingScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: SizedBox(
                                width: maxW,
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 8),
                                      Center(child: _LogoFrame(size: logoDim)),
                                      const SizedBox(height: 18),
                                      _sectionIntro(),
                                      const SizedBox(height: 12),
                                      _labeledField(
                                        label: 'Server / IP address',
                                        hint: 'e.g. 192.168.1.10 or host:1433',
                                        controller: ipController,
                                        iconAsset: AppImage.ipaddress,
                                        validator: (value) {
                                          if (value == '') {
                                            return 'Please enter UserName';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      _labeledField(
                                        label: 'Database username',
                                        hint: 'SQL login user',
                                        controller: userNameController,
                                        iconAsset: AppImage.user,
                                        validator: (value) {
                                          if (value == '') {
                                            return 'Please enter UserName';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      _labeledField(
                                        label: 'Password',
                                        hint: 'Enter password',
                                        controller: passwordController,
                                        iconAsset: AppImage.padlock,
                                        obscure: isShow,
                                        suffix: IconButton(
                                          onPressed: () {
                                            print(isShow);
                                            setState(() => isShow = !isShow);
                                          },
                                          style: IconButton.styleFrom(
                                            foregroundColor: _textSecondary,
                                          ),
                                          icon: Image.asset(
                                            !isShow
                                                ? AppImage.hide
                                                : AppImage.show,
                                            width: 22,
                                            height: 22,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value != '') {
                                            return 'Please enter password';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      _labeledField(
                                        label: 'Database name',
                                        hint: 'e.g. NextMain',
                                        controller: databaseController,
                                        iconAsset: AppImage.database,
                                        textInputAction: TextInputAction.done,
                                        validator: (value) {
                                          if (value != '') {
                                            return 'Please enter Database Name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      _SubmitBar(
                                        label: 'Submit',
                                        color: _ctaFill,
                                        wide: w,
                                        onPressed: () => _onSubmit(),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            size: 15,
                                            color: _textSecondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Stored locally on this device only',
                                              textAlign: TextAlign.center,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                color: _textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 10,
                //     vertical: 6,
                //   ),
                //   decoration: BoxDecoration(
                //     color: _brand.withOpacity(0.12),
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(
                //       color: _brand.withOpacity(0.28),
                //       width: 1,
                //     ),
                //   ),
                //   child: Text(
                //     'SETUP',
                //     style: GoogleFonts.plusJakartaSans(
                //       fontSize: 10,
                //       fontWeight: FontWeight.w800,
                //       letterSpacing: 1.2,
                //       height: 1,
                //       color: _brand,
                //     ),
                //   ),
                // ),
                Text(
                  'Connection',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Enter your server details to connect DataCare Ultra.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.45,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(
          height: 1,
          thickness: 1,
          color: _border,
          indent: 4,
          endIndent: 4,
        ),
      ],
    );
  }

  Widget _buildHeader(double width) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(8, 10, 16, width < 400 ? 16 : 22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_brandDark, _brand],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!widget.isFromSplash)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        color: Colors.white.withOpacity(0.2),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: width < 360 ? 17 : 19,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isFromSplash ? 12 : 52,
                    ),
                    child: Text(
                      'IP ADDRESS SETTING',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: width < 340 ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Secure server configuration',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void getDataFromStorage() async {
    String? host = await Preffrance().getString(Keys.HOST);
    String? username = await Preffrance().getString(Keys.USERNAME);
    String? dbPass = await Preffrance().getString(Keys.PASSWORD);
    if (host != '' || host != null) {
      ipController.text = host ?? '';
    }
    if (username != '' || username != null) {
      userNameController.text = username ?? 'sa';
    }
    if (dbPass != '' || dbPass != null) {
      passwordController.text = dbPass ?? 'datacare@123';
    }
    databaseController.text = 'NextMain';
    setState(() {});
  }
}

class _LogoFrame extends StatelessWidget {
  const _LogoFrame({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Image.asset(
        AppImage.appLogo,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.label,
    required this.color,
    required this.wide,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final double wide;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final h = math.max(48.0, 44 + wide * 0.01);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: color.withOpacity(0.4),
        minimumSize: Size(double.infinity, h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: wide < 360 ? 16 : 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 20),
        ],
      ),
    );
  }
}
