import 'package:flutter/material.dart';
/*
class AppTheme {
  //final String id;
  final Color backgroundColor;
  final Color textColor;
  final Color textColorFaded;

  const AppTheme({ 
    //@required this.id, 
    this.backgroundColor, 
    this.textColor, 
    this.textColorFaded
  });
}

class AppThemes {
  // This class is not meant to be instantiated or extended; this constructor prevents instantiation and extension.
  AppThemes._();

  static const AppTheme light = ThemeData(
    //id: 'light',
    backgroundColor: Colors.white,
    textColor: Colors.black,
    textColorFaded: Colors.black12,
    brightness: Brightness.dark
  );

  static const AppTheme dark = AppTheme(
    //id: 'dark',
    backgroundColor: Colors.black,
    textColor: Colors.white,
    textColorFaded: Colors.white12
  );
}
*/
/*
final globalTheme = ThemeData(
  primarySwatch: Colors.blue,
);
*/

class Themes {
  // This class is not meant to be instantiated or extended; this constructor prevents instantiation and extension.
  Themes._();

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    cardTheme: const CardTheme(
      shadowColor: Colors.black45,
    ),
    hintColor: Colors.black.withOpacity(0.085)
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    cardTheme: CardTheme(
      color: Colors.grey[900]
    ),
    hintColor: Colors.white.withOpacity(0.2)
  );
  
  
  /*
  static AppTheme light = AppTheme(
    themeData: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
    ),
    colors: AppThemeColors(
      contrasting: Colors.black
    )
  );
  */
}
/*
class AppTheme {
  ThemeData themeData;
  AppThemeColors colors;

  AppTheme({
    required this.themeData,
    required this.colors
  });
}

class AppThemeColors {
  Color contrasting;

  AppThemeColors({
    required this.contrasting
  });
}
*/