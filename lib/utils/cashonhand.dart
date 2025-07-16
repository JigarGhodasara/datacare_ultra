import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../provider/commonCompanyYearSelectionProvider.dart';

class CashOnHandBox extends StatelessWidget {
  final String cashAmount;

  const CashOnHandBox({
    super.key,
    required this.cashAmount,
  });

  @override
  Widget build(BuildContext context) {
    final coSName = Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).CoSname;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFFD2AD54), // 🔥 Clean premium grey
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: -3,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF243E5B), size: 28),
          // SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Cash on Hand ${coSName == "UAE" ? "(AED)" : ""}",
                  style: GoogleFonts.nunito(
                    color: Color(0xFF243E5B),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  "${cashAmount.replaceAll('-', '')} ${cashAmount.contains('-')?"Dr":"Cr"}",
                  style: GoogleFonts.nunito(
                    color: Color(0xFF243E5B),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
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
