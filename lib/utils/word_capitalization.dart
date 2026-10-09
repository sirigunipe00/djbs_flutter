import 'package:flutter/services.dart';

String capitalizeWords(String input) {
  if (input.isEmpty) return input;
  final buffer = StringBuffer();
  var startOfWord = true;
  for (final rune in input.runes) {
    final char = String.fromCharCodes([rune]);
    if (char == ' ') {
      buffer.write(char);
      startOfWord = true;
      continue;
    }
    buffer.write(startOfWord ? char.toUpperCase() : char);
    startOfWord = false;
  }
  return buffer.toString();
}

class WordCapitalizationFormatter extends TextInputFormatter {
  const WordCapitalizationFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = capitalizeWords(newValue.text);
    if (formatted == newValue.text) return newValue;

    return TextEditingValue(
      text: formatted,
      selection: _clampSelection(newValue.selection, formatted.length),
      composing: _clampComposing(newValue.composing, formatted.length),
    );
  }

  TextSelection _clampSelection(TextSelection selection, int length) {
    return TextSelection(
      baseOffset: selection.baseOffset.clamp(0, length),
      extentOffset: selection.extentOffset.clamp(0, length),
      affinity: selection.affinity,
      isDirectional: selection.isDirectional,
    );
  }

  TextRange _clampComposing(TextRange composing, int length) {
    if (!composing.isValid) return TextRange.empty;
    final start = composing.start.clamp(0, length);
    final end = composing.end.clamp(0, length);
    if (start > end) return TextRange.empty;
    return TextRange(start: start, end: end);
  }
}
