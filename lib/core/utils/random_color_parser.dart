class RandomColorParser {
  String parseHexColor(String input) {
    String hex = input.toLowerCase();

    // Bỏ prefix 0x nếu có
    if (hex.startsWith('0x')) {
      hex = hex.substring(2);
    }

    // Nếu dư 1 byte alpha (10 hex) → bỏ 2 ký tự đầu
    if (hex.length == 10) {
      hex = hex.substring(2);
    }

    if (hex.length != 8) {
      throw FormatException('Invalid ARGB color: $input');
    }

    return hex;
  }
}