import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

void customToast({required String msg}) {
  Fluttertoast.showToast(
    msg: '  $msg  ',
    fontSize: Get.width * 0.042,
    backgroundColor: Colors.grey,
    gravity: ToastGravity.BOTTOM,
    toastLength: Toast.LENGTH_LONG,
    timeInSecForIosWeb: 2,
  );
}
