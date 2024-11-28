import 'package:flutter/services.dart';

class HexInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.toUpperCase();

    if (RegExp(r'^[0-9A-F]*$').hasMatch(newText)) {
      return newValue.copyWith(
        text: newText,
        selection: newValue.selection,
      );
    }
    
    return oldValue;
  }
}
