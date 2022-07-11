import 'package:flutter/material.dart';

final List<Color> userColorPallete = <Color>[
  Colors.blue[200]!,
  Colors.red[200]!,
  Colors.green[200]!,
  Colors.orange[200]!,
  Colors.cyan[200]!,
  Colors.lightBlue[200]!,
  Colors.lightGreen[200]!,
  Colors.purple[200]!,
  Colors.indigo[200]!,
  Colors.teal[200]!,
  Colors.red[200]!,
];

Color nickColor(String nick) {
  return userColorPallete[nick.hashCode % userColorPallete.length];
}
