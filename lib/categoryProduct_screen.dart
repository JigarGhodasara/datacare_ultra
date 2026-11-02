import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:DataCareUltra/provider/loading_provider.dart';
import 'package:DataCareUltra/utils/app_toast.dart';
import 'package:DataCareUltra/utils/image_url.dart';
import 'package:DataCareUltra/mySql_services.dart';
import 'package:DataCareUltra/provider/commonCompanyYearSelectionProvider.dart';
import 'package:DataCareUltra/tagEstimate_screen.dart';
import 'package:DataCareUltra/utils/colors.dart';
import 'package:DataCareUltra/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sql_connection/sql_connection.dart';

class CategoryproductScreen extends StatefulWidget {
  String screenName;
  String prCode;
  String ItType;
  CategoryproductScreen(
      {Key? key,
      required this.screenName,
      required this.prCode,
      required this.ItType})
      : super(key: key);

  @override
  State<CategoryproductScreen> createState() => _CategoryproductScreenState();
}

class _CategoryproductScreenState extends State<CategoryproductScreen> {
  List<dynamic> categoryProductList = [];
  List<dynamic> searchCategoryProductList = [];
  final sqlConnection = SqlConnection.getInstance();
  List<dynamic> groupData = [
    {"GR_CODE": "", "GR_NAME": "Select Group"}
  ];
  List<dynamic> designData = [
    {"DESIGN_NO": "Select Design"}
  ];
  String selectItem = "Select Item";
  dynamic selectedGroupCode = {"GR_CODE": "", "GR_NAME": "Select Group"};
  dynamic selectedDesignNo = "Select Design";
  String co_code = "";
  String year = "";
  String lc_code = "";
  late LoadingProvider loadingProvider;
  TextEditingController designSearchController = TextEditingController();
  List<dynamic> designSuggestionList = [];
  OverlayEntry? designOverlayEntry;
  final LayerLink _layerLink = LayerLink();

  static final Color _cta = AppColor.blueColor;
  static const Color _pageBg = Color(0xFFF4F6FA);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  TextStyle _pjSans({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color? color,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? _textPrimary,
      height: 1.35,
    );
  }

  BoxDecoration _fieldShell() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border.withValues(alpha: 0.9)),
      boxShadow: [
        BoxShadow(
          color: _cta.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  InputDecoration _mainSearchDecoration() {
    return InputDecoration(
      hintText: 'Search with tag no.',
      hintStyle: _pjSans(
        size: 14,
        weight: FontWeight.w500,
        color: _textSecondary.withValues(alpha: 0.75),
      ),
      counterText: '',
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _cta.withValues(alpha: 0.12),
                _cta.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.search_rounded, color: _cta, size: 22),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _border, width: 1.25),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _cta, width: 1.75),
      ),
    );
  }

  Widget _kvLine(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: _pjSans(
                size: 12,
                weight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ),
          Text(
            ': ',
            style: _pjSans(
              size: 12,
              weight: FontWeight.w600,
              color: _border,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: _pjSans(
                size: emphasize ? 15 : 13,
                weight: emphasize ? FontWeight.w800 : FontWeight.w700,
                color: emphasize ? _cta : _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showDesignSuggestions() {
    hideDesignSuggestions();

    final overlay = Overlay.of(context);

    designOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 60,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 50),
            child: Material(
              elevation: 0,
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _cta.withValues(alpha: 0.14)),
                  boxShadow: [
                    BoxShadow(
                      color: _cta.withValues(alpha: 0.14),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: designSuggestionList.length,
                    itemBuilder: (context, index) {
                      final design = designSuggestionList[index];
                      return Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () {
                            designSearchController.text = design["DESIGN_NO"];
                            selectedDesignNo = design["DESIGN_NO"];
                            hideDesignSuggestions();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Text(
                              '${design["DESIGN_NO"]}',
                              style: _pjSans(
                                size: 14,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(designOverlayEntry!);
  }

  void hideDesignSuggestions() {
    if (designOverlayEntry != null) {
      designOverlayEntry!.remove();
      designOverlayEntry = null;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Update your state here
      getProductList();
    });
    getFilterData();
  }

  void getProductList() async {
    loadingProvider.startLoading();
    setState(() {});
    try {
      String grpCode = "";
      if (selectedGroupCode["GR_NAME"] != "Select Group") {
        groupData.forEach((action) {
          if (action["GR_NAME"] == selectedGroupCode["GR_NAME"]) {
            grpCode = action["GR_CODE"];
          }
        });
        print("grpCode ${grpCode}");
      }

      print("prCode ${widget.prCode}");
      co_code = Provider.of<CommonCompanyYearSelectionProvider>(context,
              listen: false)
          .co_code;
      year = Provider.of<CommonCompanyYearSelectionProvider>(context,
              listen: false)
          .co_year;
      lc_code = Provider.of<CommonCompanyYearSelectionProvider>(context,
              listen: false)
          .lc_code;
      if (Platform.isAndroid) {
        String query =
            "SELECT A.TAG_NO As TagNo,B.IT_NAME As ItmName,D.PR_CODE,C.ITM_SIZE As Size,C.ITM_PCS as Pcs,C.ITM_GWT As Grwt,C.ITM_NWT AS NetWt,C.LBR_PRC As LbrPrc,C.LBR_RATE As LRate,C.LBR_AMT LbrAmt,C.OTH_AMT OthAmt,C.ITM_MRP As Mrp,C.VCH_SRNO,C.LBR_TYPE AS LbrType,C.RATE_TYPE AS RateType,B.GR_CODE as GrCode, C.DESIGN_IMG_ID AS DesignImgId, C.DESIGN_NO from ((MAIN_STOCK AS A INNER JOIN BAR_DETL AS C ON A.CO_CODE = C.CO_CODE  And A.TAG_NO = C.TAG_NO And A.VCH_SRNO = C.VCH_SRNO And A.IT_CODE = C.IT_CODE) LEFT JOIN  ITEM_MAST AS B ON A.CO_CODE = B.CO_CODE And A.IT_CODE = B.IT_CODE) LEFT JOIN PRODUCT_MAST AS D ON B.CO_CODE = D.CO_CODE And B.PR_CODE = D.PR_CODE WHERE A.CO_CODE = '$co_code' AND A.LC_CODE = '$lc_code' AND A.CO_YEAR = '$year' ";

        if (widget.ItType != '') {
          query += "AND B.IT_TYPE = '${widget.ItType}' ";
        }
        if (widget.prCode != "") {
          query += "AND D.PR_CODE = '${widget.prCode}' ";
        }
        // use for the filler
        if (grpCode != "") {
          query += "AND B.GR_CODE = '" + grpCode + "' ";
        }
        if (selectedDesignNo != "Select Design" && selectedDesignNo != "") {
          print("selectedDesignNo['DESIGN_NO'] ${selectedDesignNo}");
          query += "AND C.DESIGN_NO = '" + selectedDesignNo + "' ";
        }
        // if(selectItem != "Select Item"){
        //   query += "AND B.GR_CODE = '"+selectItem.splitMapJoin(" ")[1]+"'";
        // }
        // if !self.Sgroup.isEmpty {
        // query += "AND B.GR_CODE = '\(self.Sgroup)' "
        // }
        //

        // if !self.SItem.isEmpty {
        // query += "AND B.IT_CODE = '\(self.SItem)' "
        // }
        //weight Filter
//        if (Int(self.SWeightMin) != 0) {
//            query += "AND C.ITM_NWT >= '\(self.SWeightMin)'"
//        }
//
//        if (Int(SWeightMax) != 0) {
//            query += "AND C.ITM_NWT <= '\(self.SWeightMax)'"
//        }

        query +=
            "GROUP BY D.PR_CODE,A.TAG_NO,B.IT_NAME,B.IT_CODE,C.ITM_SIZE,C.ITM_PCS,C.ITM_GWT,C.ITM_NWT,C.LBR_PRC,C.LBR_RATE,C.LBR_AMT,C.OTH_AMT,  C.ITM_MRP,C.VCH_SRNO,C.LBR_TYPE,C.RATE_TYPE, B.GR_CODE, C.DESIGN_IMG_ID,C.DESIGN_NO HAVING SUM(CASE WHEN ITM_SIGN='+' THEN A.VCH_SRNO ELSE -A.VCH_SRNO END) > 0  ORDER BY A.TAG_NO DESC";
        log("query ${query}");
        dynamic result = await sqlConnection.queryDatabase(query);
        log("Resuult ${result}");
        categoryProductList = jsonDecode(result);
        searchCategoryProductList = jsonDecode(result);
      } else {
        dynamic result = await MySQLService().getProducts(
            co_code, lc_code, year, widget.prCode, widget.ItType, grpCode);
        print("Reee $result");
        categoryProductList = result[0];

        if (selectItem != "Select Item") {
          // searchCategoryProductList.removeWhere((e)=> selectItem != e["ItmName"]);
          result[0].forEach((e) {
            if (selectItem == e["ItemName"]) {
              searchCategoryProductList.add(e);
            }
          });
        } else {
          searchCategoryProductList = result[0];
        }
      }
    } catch (e) {
      log('Error fetching product list: $e');
      if (mounted) {
        showAppToast(context, "Could not load products. Please try again.");
      }
    } finally {
      loadingProvider.stopLoading();
      if (mounted) setState(() {});
    }
  }

  fillterData({
    required String selectedItem,
    required dynamic selectGrp,
    required dynamic selectDesign,
  }) {
    dynamic selectedGroupvalue = selectGrp;
    String item = selectedItem;
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: BoxDecoration(
                    color: _pageBg,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                    boxShadow: [
                      BoxShadow(
                        color: _cta.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 10, bottom: 8),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _border,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        foregroundColor: _textSecondary,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Filters',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                          color: _cta,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 48),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        selectItem = 'Select Item';
                                        selectedGroupCode = {
                                          'GR_CODE': '',
                                          'GR_NAME': 'Select Group'
                                        };
                                        selectedDesignNo = 'Select Design';
                                        getProductList();
                                        hideDesignSuggestions();
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Clear all',
                                        style: _pjSans(
                                          size: 13,
                                          weight: FontWeight.w700,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _cta,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () {
                                        selectItem = item;
                                        selectedGroupCode = selectedGroupvalue;
                                        selectedDesignNo =
                                            designSearchController.text;
                                        hideDesignSuggestions();
                                        getProductList();
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Apply',
                                        style: _pjSans(
                                          size: 14,
                                          weight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: _border.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Group',
                            style: _pjSans(
                              size: 13,
                              weight: FontWeight.w700,
                              color: _cta,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: _fieldShell(),
                            child: DropdownButtonHideUnderline(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor: Colors.white,
                                ),
                                child: DropdownButton(
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.expand_more_rounded,
                                    color: _cta,
                                  ),
                                  value: selectedGroupvalue['GR_NAME'],
                                  items: groupData.map((items) {
                                    return DropdownMenuItem(
                                      value: items['GR_NAME'],
                                      child: Text(
                                        '${items['GR_NAME']}',
                                        style: _pjSans(size: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    selectedGroupvalue = {
                                      'GR_CODE': '',
                                      'GR_NAME': value
                                    };
                                    setModalState(() {});
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Item',
                            style: _pjSans(
                              size: 13,
                              weight: FontWeight.w700,
                              color: _cta,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: _fieldShell(),
                            child: DropdownButtonHideUnderline(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor: Colors.white,
                                ),
                                child: DropdownButton(
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.expand_more_rounded,
                                    color: _cta,
                                  ),
                                  value: item,
                                  items: [
                                    'Select Item',
                                    '${widget.screenName} 18K',
                                    '${widget.screenName} 916'
                                  ].map((items) {
                                    return DropdownMenuItem(
                                      value: items,
                                      child: Text(
                                        items,
                                        style: _pjSans(size: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    item = value!;
                                    setModalState(() {});
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Design',
                            style: _pjSans(
                              size: 13,
                              weight: FontWeight.w700,
                              color: _cta,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CompositedTransformTarget(
                            link: _layerLink,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: _fieldShell(),
                              child: TextField(
                                controller: designSearchController,
                                style: _pjSans(size: 14),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
                                  hintText: 'Search design',
                                  hintStyle: _pjSans(
                                    size: 14,
                                    weight: FontWeight.w500,
                                    color:
                                        _textSecondary.withValues(alpha: 0.65),
                                  ),
                                ),
                                onChanged: (value) {
                                  designSuggestionList = designData
                                      .where((e) => e['DESIGN_NO']
                                          .toString()
                                          .toLowerCase()
                                          .contains(value.toLowerCase()))
                                      .toList();

                                  if (designSuggestionList.isEmpty ||
                                      value.isEmpty) {
                                    hideDesignSuggestions();
                                  } else {
                                    showDesignSuggestions();
                                  }

                                  setModalState(() {});
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    // showModalBottomSheet(
    //     constraints: BoxConstraints(
    //       maxHeight: double.infinity,
    //     ),
    //     scrollControlDisabledMaxHeightRatio: 0.8,
    //     useSafeArea: true,
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.only(
    //           topLeft: Radius.circular(25), topRight: Radius.circular(25)),
    //     ),
    //     context: context,
    //     builder: (context) => StatefulBuilder(builder: (context, setModalState) {
    //
    //
    //       return Padding(
    //         padding: const EdgeInsets.symmetric(horizontal: 15.0),
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Padding(
    //               padding: const EdgeInsets.only(top: 20.0, bottom: 5),
    //               child: Row(
    //                 children: [
    //                   GestureDetector(
    //                       onTap: () => Navigator.pop(context),
    //                       child: Icon(Icons.close)),
    //                   Spacer(),
    //                   GestureDetector(
    //                     onTap: (){
    //                       selectItem = "Select Item";
    //                       selectedGroupCode = {"GR_CODE": "", "GR_NAME": "Select Group"};
    //                       selectedDesignNo =  "Select Design";
    //                       getProductList();
    //                       hideDesignSuggestions();
    //                       Navigator.pop(context);
    //                     },
    //                     child: Text(
    //                       "Clear All",
    //                       style: TextStyle(
    //                           fontSize: 15,
    //                           color: Color(0xFF006EB7),
    //                           fontWeight: FontWeight.w600),
    //                     ),
    //                   ),
    //                   SizedBox(
    //                     width: 20,
    //                   ),
    //                   GestureDetector(
    //                     onTap: (){
    //                       selectItem = item;
    //                       selectedGroupCode = selectedGroupvalue;
    //                       selectedDesignNo = designSearchController.text;
    //                       hideDesignSuggestions();
    //                       print("Design $selectedDesignvalue");
    //                       getProductList();
    //
    //
    //
    //
    //                       Navigator.pop(context);
    //                     },
    //                     child: Text(
    //                       "Apply Filter",
    //                       style: TextStyle(
    //                           fontSize: 15,
    //                           color: Color(0xFF006EB7),
    //                           fontWeight: FontWeight.w600),
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //             Divider(),
    //             SizedBox(
    //               height: 20,
    //             ),
    //             Expanded(
    //                 child: SingleChildScrollView(
    //                   child: Column(
    //                     crossAxisAlignment: CrossAxisAlignment.start,
    //                     children: [
    //                       Text(
    //                         "Group",
    //                         style: TextStyle(
    //                             fontSize: 15,
    //                             color: Color(0xFF006EB7),
    //                             fontWeight: FontWeight.w600),
    //                       ),
    //                       Container(
    //                         margin: EdgeInsets.only(top: 10),
    //                         decoration: BoxDecoration(
    //                             color: Color(0xFFe7edeb),
    //                             borderRadius: BorderRadius.circular(8.0)),
    //                         child: DropdownButtonHideUnderline(
    //                           child: Theme(
    //                             data: Theme.of(context).copyWith(
    //                               canvasColor: Color(0xfff1f1f1),
    //                             ),
    //                             child: DropdownButton2(
    //                                 dropdownStyleData: DropdownStyleData(),
    //                                 isExpanded: true,
    //                                 value: selectedGroupvalue["GR_NAME"],
    //                                 items: groupData
    //                                     .map((dynamic items) {
    //                                   return DropdownMenuItem(
    //                                     value: items["GR_NAME"],
    //                                     child: Text(items["GR_NAME"]),
    //                                   );
    //                                 }).toList(),
    //                                 onChanged: (value) {
    //                                   selectedGroupvalue = {
    //                                     "GR_CODE": "",
    //                                     "GR_NAME": value
    //                                   };
    //                                   setModalState(() {});
    //                                 }),
    //                           ),
    //                         ),
    //                       ),
    //                       SizedBox(
    //                         height: 10,
    //                       ),
    //                       Text(
    //                         "Item",
    //                         style: TextStyle(
    //                             fontSize: 15,
    //                             color: Color(0xFF006EB7),
    //                             fontWeight: FontWeight.w600),
    //                       ),
    //                       Container(
    //                         margin: EdgeInsets.only(top: 10),
    //                         decoration: BoxDecoration(
    //                             color: Color(0xFFe7edeb),
    //                             borderRadius: BorderRadius.circular(8.0)),
    //                         child: DropdownButtonHideUnderline(
    //                           child: Theme(
    //                             data: Theme.of(context).copyWith(
    //                               canvasColor: Color(0xfff1f1f1),
    //                             ),
    //                             child: DropdownButton2(
    //                                 dropdownStyleData: DropdownStyleData(),
    //                                 isExpanded: true,
    //                                 value: item,
    //                                 items: ["Select Item","${widget.screenName} 18K","${widget.screenName} 916"]
    //                                     .map((String items) {
    //                                   return DropdownMenuItem(
    //                                     value: items,
    //                                     child: Text(items),
    //                                   );
    //                                 }).toList(),
    //                                 onChanged: (value) {
    //                                   item = value!;
    //                                   setModalState(() {});
    //                                 }),
    //                           ),
    //                         ),
    //                       ),
    //                       SizedBox(
    //                         height: 10,
    //                       ),
    //                       // Text(
    //                       //   "Design",
    //                       //   style: TextStyle(
    //                       //       fontSize: 15,
    //                       //       color: Color(0xFF006EB7),
    //                       //       fontWeight: FontWeight.w600),
    //                       // ),
    //                       // Container(
    //                       //   margin: EdgeInsets.only(top: 10),
    //                       //   decoration: BoxDecoration(
    //                       //       color: Color(0xFFe7edeb),
    //                       //       borderRadius: BorderRadius.circular(8.0)),
    //                       //   child: DropdownButtonHideUnderline(
    //                       //     child: Theme(
    //                       //       data: Theme.of(context).copyWith(
    //                       //         canvasColor: Color(0xfff1f1f1),
    //                       //       ),
    //                       //       child: DropdownButton2(
    //                       //           dropdownStyleData: DropdownStyleData(),
    //                       //           isExpanded: true,
    //                       //           value: selectedDesignvalue["DESIGN_NO"],
    //                       //           items: designData
    //                       //               .map((dynamic items) {
    //                       //             return DropdownMenuItem(
    //                       //               value: items["DESIGN_NO"],
    //                       //               child: Text(items["DESIGN_NO"]),
    //                       //             );
    //                       //           }).toList(),
    //                       //           onChanged: (value) {
    //                       //             selectedDesignvalue = {
    //                       //               "DESIGN_NO": value,
    //                       //             };
    //                       //             setModalState(() {});
    //                       //           }),
    //                       //     ),
    //                       //   ),
    //                       // ),
    //                       SizedBox(height: 10),
    //
    //                       Text(
    //                         "Design",
    //                         style: TextStyle(
    //                           fontSize: 15,
    //                           color: Color(0xFF006EB7),
    //                           fontWeight: FontWeight.w600,
    //                         ),
    //                       ),
    //
    //                       CompositedTransformTarget(
    //                         link: _layerLink,
    //                         child: Container(
    //                           margin: EdgeInsets.only(top: 10),
    //                           padding: EdgeInsets.symmetric(horizontal: 12),
    //                           decoration: BoxDecoration(
    //                             color: Color(0xFFe7edeb),
    //                             borderRadius: BorderRadius.circular(8.0),
    //                           ),
    //                           child: TextField(
    //                             controller: designSearchController,
    //                             decoration: InputDecoration(
    //                               border: InputBorder.none,
    //                               hintText: "Search Design",
    //                             ),
    //                             onChanged: (value) {
    //                               designSuggestionList = designData
    //                                   .where((e) =>
    //                                   e["DESIGN_NO"]
    //                                       .toString()
    //                                       .toLowerCase()
    //                                       .contains(value.toLowerCase()))
    //                                   .toList();
    //
    //                               if (designSuggestionList.isEmpty || value.isEmpty) {
    //                                 hideDesignSuggestions();
    //                               } else {
    //                                 showDesignSuggestions();
    //                               }
    //
    //                               setModalState(() {});
    //                             },
    //                           ),
    //                         ),
    //                       ),
    //
    //
    //
    //                       SizedBox(
    //                         height: 40,
    //                       ),
    //                     ],
    //                   ),
    //                 ))
    //           ],
    //         ),
    //       );
    //     }));
  }

  void getFilterData() async {
    if (Platform.isAndroid) {
      var groupQuery =
          "SELECT GR_CODE,GR_NAME FROM GROUP_MAST WHERE CO_CODE='" +
              co_code +
              "'";
      dynamic groupQueryResult = await sqlConnection.queryDatabase(groupQuery);
      print("groupQueryResult ${groupQueryResult}");
      List<dynamic> groupResultData = jsonDecode(groupQueryResult);
      groupData.addAll(groupResultData);
    } else {
      dynamic grpResult = await MySQLService().getStockFilterGrpData(co_code);
      print("grpResult $grpResult");
      groupData.addAll(grpResult[0]);
    }

    if (Platform.isAndroid) {
      var designQuery = "SELECT DESIGN_NO FROM BAR_DETL WHERE CO_CODE='" +
          co_code +
          "' AND DESIGN_NO <> '' GROUP BY DESIGN_NO";
      dynamic designQueryResult =
          await sqlConnection.queryDatabase(designQuery);
      print("designQueryResult ${designQueryResult}");
      List<dynamic> groupResultData = jsonDecode(designQueryResult);
      designData.addAll(groupResultData);
    } else {
      dynamic dgnResult = await MySQLService().getStockFilterDgnData(co_code);
      print("grpResult $dgnResult");
      designData.addAll(dgnResult[0]);
    }
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
        leading: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: IconButton(
            splashRadius: 26,
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _cta,
              size: 22,
            ),
          ),
        ),
        title: Text(
          widget.screenName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            color: _cta,
          ),
        ),
        actions: [
          IconButton(
            splashRadius: 26,
            onPressed: () {
              fillterData(
                selectedItem: selectItem,
                selectGrp: selectedGroupCode,
                selectDesign: selectedDesignNo,
              );
            },
            icon: Icon(
              Icons.tune_rounded,
              color: _cta,
              size: 26,
            ),
            tooltip: 'Filters',
          ),
          const SizedBox(width: 4),
        ],
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: TextFormField(
                  cursorColor: _cta,
                  keyboardType: TextInputType.text,
                  style: _pjSans(size: 14, weight: FontWeight.w600),
                  decoration: _mainSearchDecoration(),
                  onChanged: (value) {
                    if (value != '') {
                      searchCategoryProductList = categoryProductList
                          .where((text) =>
                              text.containsKey('TagNo') &&
                              text['TagNo']
                                  .toString()
                                  .toLowerCase()
                                  .contains(value.trim().toLowerCase()))
                          .toList();
                      setState(() {});
                    } else {
                      searchCategoryProductList.clear();
                      searchCategoryProductList.addAll(categoryProductList);
                      setState(() {});
                    }
                  },
                ),
              ),
              loadingProvider.isLoading
                  ? const SizedBox.shrink()
                  : searchCategoryProductList.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        _cta.withValues(alpha: 0.12),
                                        _cta.withValues(alpha: 0.04),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: _cta.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 44,
                                    color: _cta.withValues(alpha: 0.65),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'No record found',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Adjust filters or search by tag number',
                                  style: _pjSans(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: _textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: searchCategoryProductList.length,
                            itemBuilder: (context, index) {
                              String imagePath = '';
                              print(
                                  'WEbImage ${Provider.of<CommonCompanyYearSelectionProvider>(context, listen: false).webImage}');
                              final imgProvider = Provider.of<
                                      CommonCompanyYearSelectionProvider>(
                                  context,
                                  listen: false);
                              if (tagImagesEnabled(imgProvider.webImage)) {
                                final designId =
                                    '${searchCategoryProductList[index]['DesignImgId'] ?? ''}'
                                        .trim();
                                if (designId != 'N' && designId.isNotEmpty) {
                                  imagePath = buildTagImageUrl(
                                      imgProvider.webPath, '$designId.jpg',
                                      serverHost: imgProvider.serverHost);
                                } else {
                                  final tag =
                                      '${searchCategoryProductList[index]["TagNo"] ?? ''}'
                                          .trim();
                                  final srNo = BigInt.from(
                                      searchCategoryProductList[index]
                                          ["VCH_SRNO"]);
                                  imagePath = buildTagImageUrl(
                                      imgProvider.webPath, '${tag}_$srNo.jpg',
                                      serverHost: imgProvider.serverHost);
                                }
                              }
                              print('Image AA $imagePath');
                              final row = searchCategoryProductList[index];
                              final tagStr = '${row['TagNo']}';
                              final grwtStr =
                                  double.parse(row['Grwt'].toString())
                                      .toStringAsFixed(3);
                              final netStr =
                                  double.parse(row['NetWt'].toString())
                                      .toStringAsFixed(3);

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TagestimateScreen(
                                        productImage: imagePath,
                                        tagNo: tagStr,
                                        VchSrNo: BigInt.from(row['VCH_SRNO'])
                                            .toString(),
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: index == 0 ? 6 : 12,
                                    left: 14,
                                    right: 14,
                                    bottom:
                                        searchCategoryProductList.length - 1 ==
                                                index
                                            ? 18
                                            : 0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _cta.withValues(alpha: 0.22),
                                          _cta.withValues(alpha: 0.06),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _cta.withValues(alpha: 0.1),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(1.25),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(14.5),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                height: 118,
                                                width: 118,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      _cta.withValues(
                                                          alpha: 0.06),
                                                      Colors.white,
                                                    ],
                                                  ),
                                                ),
                                                child: imagePath == ''
                                                    ? Image(
                                                        image: AssetImage(
                                                            AppImage
                                                                .placeHolder),
                                                        height: 118,
                                                        width: 118,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.network(
                                                        imagePath,
                                                        height: 118,
                                                        width: 118,
                                                        fit: BoxFit.cover,
                                                        cacheWidth: 240,
                                                        cacheHeight: 240,
                                                        errorBuilder:
                                                            (context, _, __) =>
                                                                Image(
                                                          image: AssetImage(
                                                              AppImage
                                                                  .placeHolder),
                                                          height: 118,
                                                          width: 118,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12,
                                                right: 12,
                                                bottom: 12,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${row['ItmName']}',
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: -0.25,
                                                      height: 1.25,
                                                      color: _cta,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  _kvLine(
                                                    'Tag no',
                                                    tagStr,
                                                    emphasize: true,
                                                  ),
                                                  _kvLine('Gr wt', grwtStr),
                                                  _kvLine('Net wt', netStr),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
