import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:widget_zoom/widget_zoom.dart';

class ImageScreen extends StatefulWidget {
  String url;
  String TagNo;
  String gWeight;
  String nWeight;
  ImageScreen({Key? key,required this.url,required this.TagNo,required this.gWeight,required this.nWeight}) : super(key: key);

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("UUUU ${widget.url}");
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Tag No: ${widget.TagNo}, Gross Weight : ${widget.gWeight}, Net Weight : ${widget.nWeight}'),
      ),
      child: Center(
        child: WidgetZoom(
          heroAnimationTag: 'tag',
          zoomWidget:widget.url.toLowerCase().contains("http") ? Image.network(
            widget.url,
            // width: 150,
            // height: 150,
          ) : Image.file(File(widget.url)),
        ),
      ),
    );
  }
}
