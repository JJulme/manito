import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

const kOffBlack = Color(0xFF303030);
const kGrey = Color(0xFF808080);
// const kLeadBlack = Color(0xFF212121);
// const kRaisinBlack = Color(0xFF222222);
// const kTinGrey = Color(0xFF909090);
// const kGraniteGrey = Color(0xFF606060);
// const kBasaltGrey = Color(0xFF999999);
// const kTrolleyGrey = Color(0xFF828282);
// const kNoghreiSilver = Color(0xFFBDBDBD);
// const kChristmasSilver = Color(0xFFE0E0E0);
// const kLynxWhite = Color(0xFFF7F7F7);
// const kSnowFlakeWhite = Color(0xFFF0F0F0);
// const kSeaGreen = Color(0xFF2AA952);
// const kCrayolaGreen = Color(0xFF27AE60);
const kFireOpal = Color(0xFFEB5757);

// 커스텀 색상
const kSunsetPeach = Color(0xFFD97757);
const kSunsetPeachLight = Color(0xFFFFBFA0); // primaryColorLight
const kSunsetPeachDark = Color(0xFFB65C4B); // primaryColorDark
const kDarkWalnut = Color(0xFF56423C);
const kCocoaCream = Color(0xFFbda69F);
const kFreshOlive = Color(0xFF66A051);

const kRed = Color.fromARGB(255, 255, 172, 95);
const kYellow = Color.fromARGB(255, 255, 225, 0);
const kGreen = Color.fromARGB(255, 90, 255, 95);
const kOrange = Colors.orange;
const kLightGrenn = Colors.lightGreen;

Future<bool> kOnExitConfirmation() async {
  bool exit = false;
  await kDefaultDialog(
    "Exit",
    "Are you sure do you want to exit the app?",
    onYesPressed: () {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      exit = true;
    },
  );
  return exit;
}

Future kDefaultDialog(
  String title,
  String message, {
  VoidCallback? onYesPressed,
}) async {
  if (GetPlatform.isIOS) {
    await Get.dialog(
      CupertinoAlertDialog(
        title: Text(title, style: Get.textTheme.titleMedium),
        content: Container(
          width: 0.8 * Get.width,
          child: Text(message, style: Get.textTheme.bodySmall),
        ),
        actions: [
          if (onYesPressed != null)
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Get.back();
              },
              child: Text("Cancel"),
            ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: onYesPressed,
            child: Text((onYesPressed == null) ? "OK" : "Yes"),
          ),
        ],
      ),
    );
  } else {
    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onYesPressed != null)
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: const Text("취소", style: TextStyle(color: kFireOpal)),
            ),
          TextButton(
            onPressed: () {
              if (onYesPressed != null) {
                onYesPressed();
              }
              Get.back();
            },
            child: Text(
              (onYesPressed == null) ? "OK" : "확인",
              style: const TextStyle(color: kOffBlack),
            ),
          ),
        ],
      ),
    );
  }
}
