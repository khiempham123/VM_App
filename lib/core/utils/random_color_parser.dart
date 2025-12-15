import 'package:flutter/cupertino.dart';

class RandomColorParser {
    String colorToHex(int colorInt) {
      return '#${colorInt.toRadixString(16).padLeft(8, '0').substring(2)}';
    }
}