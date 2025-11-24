import 'package:flutter/material.dart';

abstract class Disposable {
  @mustCallSuper
  void dispose();
}
