import 'package:flutter/material.dart';

class AppLocale extends ChangeNotifier {
  static final AppLocale _instance = AppLocale._internal();
  factory AppLocale() => _instance;
  AppLocale._internal();

  bool _isChinese = false;
  bool get isChinese => _isChinese;

  void toggle() {
    _isChinese = !_isChinese;
    notifyListeners();
  }

  String t(String en, String zh) => _isChinese ? zh : en;
}

final locale = AppLocale();
