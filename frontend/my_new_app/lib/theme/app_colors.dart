import 'package:flutter/material.dart';

class AppColors {
  // Neutral shades
  static const Color backgroundDark = Color(0xFF121212);
  static const Color backgroundLight = Color.fromARGB(255, 236, 236, 236);
  static const Color appBarColorDark = Color(0xFF2D2D2D);
  static const Color appBarColorLight = Color.fromARGB(255, 215, 215, 215);
  static const Color searchBoxDark = Color(0xFF1E1E1E);
  static const Color searchBoxLight = Color.fromARGB(255, 194, 194, 194);

  static const Color box2Dark = Color(0xFF2C2C2C);
  static const Color box2Light = Color.fromARGB(255, 187, 187, 187);

  static const Color box3Dark = Color(0xFF1C1C1C);
  static const Color box3Light = Color.fromARGB(255, 204, 204, 204);

  // Theme.of(context).brightness ==  Brightness.dark ? AppColors. : AppColors.,

  // Primary accents
  static const Color primaryDark = Color(0xFF00BFA6);
  static const Color primaryLight = Color(0xFF00796B);

  // Text
  static const Color textDark = Colors.white;
  static const Color textLight = Colors.black87;
  static const Color textLight2 = Color.fromARGB(255, 117, 117, 117);
  static const Color textDark2 = Colors.white38;

  static const Color circleAvatarColorDark = Colors.white12;
  static const Color circleAvatarColorWhite = Color.fromARGB(255, 79, 79, 79);

  static const LinearGradient greenTileDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(6, 131, 81, 1), Color.fromRGBO(0, 31, 18, 1)],
  );
  static const LinearGradient greenTileWhite = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(0, 127, 76, 1), Color.fromRGBO(1, 116, 68, 1)],
  );

  static const LinearGradient blueTileDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(15, 111, 179, 1), Color.fromRGBO(0, 11, 31, 1)],
  );
  static const LinearGradient blueTileWhite = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(15, 111, 179, 1), Color.fromRGBO(0, 34, 97, 1)],
  );

  static const LinearGradient yelloweTileDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(237, 202, 3, 1), Color.fromRGBO(41, 43, 0, 1)],
  );
  static const LinearGradient yellowTileWhite = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(237, 202, 3, 1), Color.fromRGBO(171, 178, 51, 1)],
  );

  static const LinearGradient orangeTileDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(226, 93, 22, 1), Color.fromRGBO(44, 28, 1, 1)],
  );
  static const LinearGradient orangeTileWhite = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(226, 93, 22, 1), Color.fromRGBO(148, 52, 4, 1)],
  );

  static const LinearGradient purplrTileDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(106, 23, 169, 1), Color.fromRGBO(34, 2, 61, 1)],
  );
  static const LinearGradient purplrTileWhite = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(106, 23, 169, 1), Color.fromRGBO(60, 0, 110, 1)],
  );

  static const LinearGradient greenButtondarktheme = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(208, 227, 64, 1), Color.fromRGBO(28, 54, 6, 1)],
  );
  static const LinearGradient greenButtonwhitetheme = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(184, 200, 57, 1), Color.fromRGBO(74, 144, 18, 1)],
  );

  static const LinearGradient redbuttondarktheme = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(255, 71, 139, 1), Color.fromRGBO(58, 11, 30, 1)],
  );

  static const LinearGradient redbuttonwhitetheme = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(255, 71, 139, 1), Color.fromRGBO(133, 11, 60, 1)],
  );

  static const LinearGradient tileGradDark = LinearGradient(
    colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tileGradLight = LinearGradient(
    colors: [
      Color.fromARGB(255, 208, 208, 246),
      Color.fromARGB(255, 56, 51, 62),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient groupBoxDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(27, 27, 27, 1), Color.fromRGBO(53, 53, 53, 1)],
  );

  static const LinearGradient groupBoxLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromRGBO(157, 175, 157, 1),
      Color.fromRGBO(174, 161, 161, 1),
    ],
  );

  static const LinearGradient redTileDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(178, 3, 70, 1), Color.fromRGBO(61, 2, 13, 1)],
  );
  static const LinearGradient redTileLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(159, 29, 79, 1), Color.fromRGBO(136, 3, 28, 1)],
  );
  // Gradients
}



// use this 
// Theme.of(context).brightness ==  Brightness.dark ? AppColors. : AppColors.,