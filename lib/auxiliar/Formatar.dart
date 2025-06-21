import 'package:flutter/services.dart';

class Formatar {

  /// Formatter para CPF
  static TextInputFormatter cpf() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
      String formatted = '';

      if (text.length >= 1) {
        formatted = text.substring(0, text.length >= 3 ? 3 : text.length);
      }
      if (text.length >= 4) {
        formatted += '.${text.substring(3, text.length >= 6 ? 6 : text.length)}';
      }
      if (text.length >= 7) {
        formatted += '.${text.substring(6, text.length >= 9 ? 9 : text.length)}';
      }
      if (text.length >= 10) {
        formatted += '-${text.substring(9, text.length >= 11 ? 11 : text.length)}';
      }

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  /// Formatter para Telefone
  static TextInputFormatter telefone() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
      String formatted = '';

      if (text.length >= 1) {
        formatted = '(${text.substring(0, text.length >= 2 ? 2 : text.length)}';
      }
      if (text.length >= 3) {
        formatted += ') ${text.substring(2, text.length >= 7 ? 7 : text.length)}';
      }
      if (text.length >= 8) {
        formatted += '-${text.substring(7, text.length >= 11 ? 11 : text.length)}';
      }

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }
}
