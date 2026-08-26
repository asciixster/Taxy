import 'package:flutter/material.dart';

abstract final class AppNavigation {
  static Future<T?> push<T>(BuildContext context, Widget screen) =>
      Navigator.of(context)
          .push<T>(MaterialPageRoute<T>(builder: (_) => screen));

  static Future<T?> replace<T, TO>(BuildContext context, Widget screen) =>
      Navigator.of(context)
          .pushReplacement<T, TO>(MaterialPageRoute<T>(builder: (_) => screen));
}
