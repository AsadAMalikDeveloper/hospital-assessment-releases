import 'package:flutter/material.dart';

class text extends StatelessWidget {
  String? labelText;
  double? fontSize;
  var fontStyle;
  var fontWeight;
  var textColor;
  var textAlignment;
  
  text({
    Key? key,
    required this.labelText,
    required this.fontSize,
    required this.fontWeight,
    required this.textColor,
    this.textAlignment,
    required this.fontStyle
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(labelText!,
      softWrap: true,

      style: TextStyle(
        fontSize: fontSize,
        fontFamily: fontStyle,
        fontWeight: fontWeight,
        color: textColor,
      ),
      textAlign: textAlignment,
    );
  }
}