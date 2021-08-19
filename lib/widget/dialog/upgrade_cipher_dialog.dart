import 'package:coda_wallet/widget/dialog/remove_wallet_widget.dart';
import 'package:coda_wallet/widget/dialog/upgrade_cipher_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showUpgradeCihperDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5.w))
        ),
        child: UpgradeCipherWidget()
      );
    }
  );
}