import 'package:flutter/material.dart';

const Color chargeColor = Color.fromRGBO(30, 212, 51, 1);

class Themes {
  // This class is not meant to be instantiated or extended; this constructor prevents instantiation and extension.
  Themes._();

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    cardTheme: const CardTheme(
      shadowColor: Colors.black45,
    ),
    hintColor: Colors.black.withOpacity(0.085),
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    cardTheme: CardTheme(
      color: Colors.grey[900]
    ),
    hintColor: Colors.white.withOpacity(0.2)
  );
}
