import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manito/main.dart';

void showCommonToast(String msg) {
  Fluttertoast.showToast(
    msg: '  $msg  ',
    fontSize: width * 0.042,
    backgroundColor: Colors.black87,
    gravity: ToastGravity.BOTTOM,
    toastLength: Toast.LENGTH_LONG,
    timeInSecForIosWeb: 2,
  );
}
