import 'dart:io';

void main() async {
  final file = File('reproduce_output.txt');
  final sink = file.openWrite();

  void log(String message) {
    sink.writeln(message);
    print(message);
  }

  log("--- Testing Card Number ---");
  // Case 1: 4 lines
  String text4Lines = "1234\n5678\n9012\n3456";
  parseCard(text4Lines, "4 Lines", log);

  // Case 2: 2 lines
  String text2Lines = "1234 5678\n9012 3456";
  parseCard(text2Lines, "2 Lines", log);

  // Case 3: 1 line
  String text1Line = "1234 5678 9012 3456";
  parseCard(text1Line, "1 Line", log);

  // Case 4: With noise (Strategy B target)
  String textNoise = "VISA\n1234\nVALID THRU\n5678\n9012\n3456\nEXP 12/25";
  parseCard(textNoise, "With Noise (Strategy B)", log);

  // Case 5: 4 lines with noise
  String text4LinesNoise =
      "1234\nSome Text\n5678\nMore Text\n9012\nEnd Text\n3456";
  parseCard(text4LinesNoise, "4 Lines With Interspersed Text", log);

  log("\n--- Testing Expiry Date ---");
  String text = "12/25";
  parseExpiry(text, "Simple MM/YY", log);

  String text2 = "12 / 25";
  parseExpiry(text2, "Spaces MM / YY", log);

  String text3 = "12-2025";
  parseExpiry(text3, "MM-YYYY", log);

  String text4 = "VALID THRU 12/25";
  parseExpiry(text4, "With Text", log);

  String text5 = "12\n/\n25";
  parseExpiry(text5, "Split Lines", log);

  await sink.close();
}

void parseCard(String text, String label, Function(String) log) {
  log("Testing: $label");
  String? result = _parseCardNumberStrategyA(text);
  if (result == null) {
    log("  Strategy A failed, trying B...");
    result = _parseCardNumberStrategyB(text);
  }

  if (result != null) {
    log("  SUCCESS: Found $result");
  } else {
    log("  FAILURE: No card number found.");
  }
}

String? _parseCardNumberStrategyA(String text) {
  String cleanedOneLine = text.replaceAll('\n', ' ');
  final RegExp cardRegExp = RegExp(r'(?:[0-9][-\s]*){13,19}');
  final Iterable<RegExpMatch> matches = cardRegExp.allMatches(cleanedOneLine);

  for (final match in matches) {
    final String raw = match.group(0) ?? '';
    final String candidate = raw.replaceAll(RegExp(r'[^0-9]'), '');

    if (candidate.length < 13 || candidate.length > 19) continue;
    // Mock Luhn check: assume true for test if length is valid
    // In real code we check luhn. Here we just want to see if extraction works.
    return candidate;
  }
  return null;
}

String? _parseCardNumberStrategyB(String text) {
  final String allDigits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (allDigits.length < 13) return null;

  const List<int> lengthsToCheck = [16, 15, 14, 13];

  for (int len in lengthsToCheck) {
    for (int i = 0; i <= allDigits.length - len; i++) {
      String candidate = allDigits.substring(i, i + len);
      // Mock Luhn check
      return candidate;
    }
  }
  return null;
}

void parseExpiry(String text, String label, Function(String) log) {
  log("Testing: $label");
  final RegExp expiryRegExp = RegExp(r'(0[1-9]|1[0-2])\s*[/.-]\s*([0-9]{2,4})');
  final RegExpMatch? expiryMatch = expiryRegExp.firstMatch(text);

  if (expiryMatch != null) {
    String month = expiryMatch.group(1)!;
    String year = expiryMatch.group(2)!;
    if (year.length == 4) year = year.substring(2);
    log("  Found Expiry: $month/$year");
  } else {
    log("  No Expiry found.");
  }
}
