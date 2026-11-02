import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:DataCareUltra/company_year_selection.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/setting_screen.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:DataCareUltra/utils/keys.dart';
import 'package:DataCareUltra/utils/preffrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

import 'mySql_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _brand = Color(0xFF1565C0);
  static const Color _brandDark = Color(0xFF0D47A1);
  static const Color _sheetSurface = Color(0xFFF8FAFC);
  static const Color _inputFill = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFCBD5E1);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  bool isShow = true;
  final sqlConnection = SqlConnection.getInstance();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _loggingIn = false;

  Color get _ctaFill => AppColor.PRIMARY_COLOR ?? _brand;

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _openSettings() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/server_settings'),
        builder: (context) => SettingScreen(
          key: UniqueKey(),
          isFromSplash: false,
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Future<void> _onLogin() async {
    await HapticFeedback.lightImpact();
    if (_loggingIn) return;

    String? host = await Preffrance().getString(Keys.HOST);
    String? userName = await Preffrance().getString(Keys.USERNAME);
    String? password = await Preffrance().getString(Keys.PASSWORD);

    if (userNameController.text == '') {
      await HapticFeedback.selectionClick();
      _showSnack('Please enter your username');
      return;
    }

    setState(() => _loggingIn = true);
    try {
      if (Platform.isAndroid) {
        var connectionStatus = await sqlConnection.connect(
          ip: host!.contains(':') ? host.split(':')[0].toString() : host,
          port: host.contains(':') ? host.split(':')[1].toString() : '1433',
          databaseName: 'NextMain',
          username: userName!,
          password: password!,
        );
        if (!mounted) return;
        if (!connectionStatus) {
          _showSnack(_connectionMessage(host));
          return;
        }
        {
          dynamic result = await sqlConnection.queryDatabase(
            "SELECT LOGIN_NAME,LOGIN_PWD,LOGIN_CATG FROM LOGIN_MAST WHERE LOGIN_NAME = '" +
                userNameController.text +
                "'",
          );
          if (result != null) {
            List data = jsonDecode(result);
            // data[0] is only safe inside this check. Reading LOGIN_CATG first
            // threw a RangeError for any username that does not exist, and
            // with no catch below that surfaced as a silent failure.
            if (data.isNotEmpty) {
              Provider.of<CommonCompanyYearSelectionProvider>(context,
                      listen: false)
                  .changeUserType(data[0]['LOGIN_CATG']);
              if (data[0]['LOGIN_PWD'] == null) {
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/company_year'),
                    builder: (context) =>
                        CompanyYearSelection(key: UniqueKey()),
                  ),
                );
              } else {
                if (data[0]['LOGIN_PWD'] == passwordController.text) {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/company_year'),
                      builder: (context) =>
                          CompanyYearSelection(key: UniqueKey()),
                    ),
                  );
                } else {
                  _showSnack('Please verify your password');
                }
              }
            } else {
              _showSnack('Please verify your username');
            }
          }
        }
      } else {
        final bool isConnect =
            await MySQLService().connectToDatabase(dbName: 'NextMain');
        if (!mounted) return;
        if (!isConnect) {
          _showSnack(_connectionMessage(host));
          return;
        }
        {
          dynamic result = await MySQLService().Login(userNameController.text);
          if (!mounted) return;
          if (result != null) {
            List data = result[0];
            if (data.isNotEmpty) {
              Provider.of<CommonCompanyYearSelectionProvider>(context,
                      listen: false)
                  .changeUserType(data[0]['LOGIN_CATG']);
              if (data[0]['LOGIN_PWD'] == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/company_year'),
                    builder: (context) =>
                        CompanyYearSelection(key: UniqueKey()),
                  ),
                );
              } else {
                if (data[0]['LOGIN_PWD'] == passwordController.text) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/company_year'),
                      builder: (context) =>
                          CompanyYearSelection(key: UniqueKey()),
                    ),
                  );
                } else {
                  _showSnack('Please verify your password');
                }
              }
            } else {
              _showSnack('Please verify your username');
            }
          }
        }
      }
    } catch (e, st) {
      // Previously a try/finally with no catch: a PlatformException from the
      // driver escaped as an unhandled exception, so the spinner stopped and
      // the user was told nothing at all. Unreachable servers are the single
      // most common support call, so the message names the address it tried.
      log('login failed', error: e, stackTrace: st);
      if (mounted) _showSnack(_loginErrorMessage(e, host));
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  /// Server address as configured, for use in an error message.
  String _hostLabel(String? host) {
    final text = (host ?? '').trim();
    if (text.isEmpty) return 'the server';
    return text.contains(':') ? text : '$text:1433';
  }

  String _connectionMessage(String? host) =>
      'Could not reach ${_hostLabel(host)}. Check that the server is running '
      'and that this device is on the same network.';

  /// Turns a driver failure into something a shop can act on.
  ///
  /// The raw text is a Java stack message ("EHOSTUNREACH", "Network error
  /// IOException") that means nothing at a counter, so the common causes are
  /// named instead. Anything unrecognised still shows its own text rather
  /// than a generic "something went wrong".
  String _loginErrorMessage(Object error, String? host) {
    final text = error.toString().toLowerCase();
    if (text.contains('ehostunreach') ||
        text.contains('no route to host') ||
        text.contains('etimedout') ||
        text.contains('econnrefused') ||
        text.contains('connection refused') ||
        text.contains('failed to connect') ||
        text.contains('network error')) {
      return _connectionMessage(host);
    }
    if (text.contains('login failed') || text.contains('password')) {
      return 'The server rejected the database login. Check the username and '
          'password on the settings screen.';
    }
    return 'Could not sign in. $error';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final padH = w < 360 ? 20.0 : math.min(28.0, w * 0.065);
    final maxW = math.min(w - 2 * padH, 420.0);
    final logoDim = (w * 0.2).clamp(72.0, h < 700 ? 88.0 : 100.0);

    final fieldRadius = BorderRadius.circular(14);
    final iconColor = _ctaFill;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _brandDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _PremiumBackdrop(height: h, width: w),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LoginHeroHeader(
                  padH: padH,
                  screenWidth: w,
                  onSettings: _openSettings,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          _sheetSurface,
                        ],
                        stops: const [0.0, 0.35],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x280F172A),
                          blurRadius: 40,
                          offset: Offset(0, -10),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Color(0x0D1565C0),
                          blurRadius: 48,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1).withOpacity(0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(padH, 10, padH, 0),
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
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Center(
                                            child: _LoginLogoFrame(
                                              size: logoDim,
                                              brandTint: iconColor,
                                            ),
                                          ),
                                          SizedBox(height: h < 640 ? 14 : 18),
                                          _LoginFormIntro(
                                            brand: _brand,
                                            compact: h < 700,
                                          ),
                                          SizedBox(height: h < 640 ? 18 : 22),
                                          Text(
                                            'Username',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: _textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: userNameController,
                                            textInputAction:
                                                TextInputAction.next,
                                            scrollPadding: EdgeInsets.only(
                                              left: 20,
                                              right: 20,
                                              top: 80,
                                              bottom: MediaQuery.viewInsetsOf(
                                                          context)
                                                      .bottom +
                                                  120,
                                            ),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: _textPrimary,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Enter username',
                                              hintStyle:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 15,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                              prefixIcon: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .only(
                                                  start: 14,
                                                  end: 6,
                                                ),
                                                child: Image.asset(
                                                  AppImage.user,
                                                  width: 22,
                                                  height: 22,
                                                  color: iconColor,
                                                ),
                                              ),
                                              prefixIconConstraints:
                                                  const BoxConstraints(
                                                minWidth: 48,
                                                maxWidth: 48,
                                                minHeight: 48,
                                                maxHeight: 48,
                                              ),
                                              filled: true,
                                              fillColor: _inputFill,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 16,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: fieldRadius,
                                                borderSide: const BorderSide(
                                                  color: _border,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: fieldRadius,
                                                borderSide: const BorderSide(
                                                  color: _border,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: fieldRadius,
                                                borderSide: BorderSide(
                                                  color: iconColor,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            'Password',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: _textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            obscureText: isShow,
                                            controller: passwordController,
                                            textInputAction:
                                                TextInputAction.done,
                                            onSubmitted: (_) => _onLogin(),
                                            scrollPadding: EdgeInsets.only(
                                              left: 20,
                                              right: 20,
                                              top: 80,
                                              bottom: MediaQuery.viewInsetsOf(
                                                          context)
                                                      .bottom +
                                                  120,
                                            ),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: _textPrimary,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Enter password',
                                              hintStyle:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 15,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                              prefixIcon: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .only(
                                                  start: 14,
                                                  end: 6,
                                                ),
                                                child: Image.asset(
                                                  AppImage.padlock,
                                                  width: 22,
                                                  height: 22,
                                                  color: iconColor,
                                                ),
                                              ),
                                              prefixIconConstraints:
                                                  const BoxConstraints(
                                                minWidth: 48,
                                                maxWidth: 48,
                                                minHeight: 48,
                                                maxHeight: 48,
                                              ),
                                              suffixIcon: IconButton(
                                                onPressed: () => setState(
                                                  () => isShow = !isShow,
                                                ),
                                                style: IconButton.styleFrom(
                                                  foregroundColor:
                                                      _textSecondary,
                                                ),
                                                icon: Image.asset(
                                                  isShow
                                                      ? AppImage.hide
                                                      : AppImage.show,
                                                  width: 22,
                                                  height: 22,
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: _inputFill,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 16,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: fieldRadius,
                                                borderSide: const BorderSide(
                                                  color: _border,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: fieldRadius,
                                                borderSide: const BorderSide(
                                                  color: _border,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: fieldRadius,
                                                borderSide: BorderSide(
                                                  color: iconColor,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: h < 640 ? 18 : 22),
                                          FilledButton(
                                            onPressed:
                                                _loggingIn ? null : _onLogin,
                                            style: FilledButton.styleFrom(
                                              backgroundColor: _ctaFill,
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor:
                                                  _ctaFill.withOpacity(0.55),
                                              elevation: 2,
                                              shadowColor:
                                                  _ctaFill.withOpacity(0.45),
                                              minimumSize: Size(
                                                double.infinity,
                                                math.max(
                                                  52.0,
                                                  48 + w * 0.01,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 24,
                                              ),
                                            ),
                                            child: _loggingIn
                                                ? SizedBox(
                                                    height: 22,
                                                    width: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      color: Colors.white
                                                          .withOpacity(0.95),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Sign in',
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          letterSpacing: 0.2,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      const Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        size: 22,
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                          const SizedBox(height: 12),
                                          Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: _border.withOpacity(0.6),
                                            indent: 8,
                                            endIndent: 8,
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.verified_user_outlined,
                                                size: 17,
                                                color: _brand.withOpacity(0.75),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  'Secure workspace access · Configure the server from the icon above',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 11.5,
                                                    color: _textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.4,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Blue hero: glass chip, wordmark with depth, refined tagline.
class _LoginHeroHeader extends StatelessWidget {
  const _LoginHeroHeader({
    required this.padH,
    required this.screenWidth,
    required this.onSettings,
  });

  final double padH;
  final double screenWidth;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final w = screenWidth;
    final titleSize = (w * 0.088).clamp(24.0, 30.0);
    final taglineSize = w < 360 ? 13.0 : 14.0;

    final titleShadowSoft = Shadow(
      color: Colors.black.withOpacity(0.22),
      offset: const Offset(0, 2),
      blurRadius: 16,
    );
    final titleShadowLift = Shadow(
      color: const Color(0xFF0D47A1).withOpacity(0.45),
      offset: const Offset(0, 4),
      blurRadius: 20,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(padH, 6, padH, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: w < 360 ? 12 : 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'DataCare ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.08,
                          color: Colors.white,
                          shadows: [titleShadowSoft, titleShadowLift],
                        ),
                      ),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFB3E5FC),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Ultra',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.08,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(0, 2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: w < 360 ? 8 : 10),
                ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: w < 400 ? double.infinity : 320),
                  child: Text(
                    'Sign in to continue to your workspace.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: taglineSize,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.76),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Material(
              color: Colors.white.withOpacity(0.16),
              shape: const CircleBorder(),
              // clipBehavior: Clip.antiAlias,
              // elevation: 0,
              // shadowColor: Colors.transparent,
              child: InkWell(
                onTap: onSettings,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium headline block under the logo: chip + title + subtitle.
class _LoginFormIntro extends StatelessWidget {
  const _LoginFormIntro({
    required this.brand,
    required this.compact,
  });

  final Color brand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 24.0 : 28.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: brand.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: brand.withOpacity(0.28),
                  width: 1,
                ),
              ),
              child: Text(
                'SECURE ACCESS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.35,
                  height: 1,
                  color: brand,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 14 : 16),
        Text(
          'Sign in',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Use your workspace username and password to continue.',
            textAlign: TextAlign.center,
            maxLines: 3,
            style: GoogleFonts.plusJakartaSans(
              fontSize: compact ? 13.0 : 14.0,
              height: 1.5,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Soft gradient + glass-style orbs for depth (no extra packages).
class _PremiumBackdrop extends StatelessWidget {
  const _PremiumBackdrop({required this.height, required this.width});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D47A1),
                Color(0xFF1565C0),
                Color(0xFF1976D2),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          right: -width * 0.15,
          top: height * 0.08,
          child: _GlowOrb(
            diameter: width * 0.72,
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        Positioned(
          left: -width * 0.25,
          top: height * 0.22,
          child: _GlowOrb(
            diameter: width * 0.55,
            color: const Color(0xFF64B5F6).withOpacity(0.12),
          ),
        ),
        Positioned(
          left: width * 0.2,
          bottom: height * 0.42,
          child: _GlowOrb(
            diameter: width * 0.35,
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _LoginLogoFrame extends StatelessWidget {
  const _LoginLogoFrame({
    required this.size,
    required this.brandTint,
  });

  final double size;
  final Color brandTint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: brandTint.withOpacity(0.14),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: brandTint.withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
