import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';

import '../widgets/Text.dart';



class Toast
{
  void showSuccessToast(String message)
  {
    Fluttertoast.showToast(
        msg: message,
        //toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  void showErrorToast(String message)
  {
    Fluttertoast.showToast(
        msg: message,
        //toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  void showErrorSnack(String errorMessage, BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: text(
            labelText: errorMessage,
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            textColor: Colors.white,fontStyle: 'Gilroy',
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5))),
        action:
        SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: scaffold.hideCurrentSnackBar
        ),
      ),
    );
  }
}