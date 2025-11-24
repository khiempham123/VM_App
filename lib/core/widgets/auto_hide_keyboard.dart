import 'package:flutter/material.dart';

class AutoHideKeyboard extends StatelessWidget {
  final Widget child;
  const AutoHideKeyboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
