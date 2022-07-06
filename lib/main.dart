import 'package:flutter/material.dart';
import 'screens/homePage.dart';

const baseFontSize = 14.0;

const textTheme = TextTheme(
      bodyText1: TextStyle(fontSize: baseFontSize, color: Colors.green),
      headline1: TextStyle(fontSize: baseFontSize + 4));

final ThemeData myTheme = ThemeData(
  primarySwatch: Colors.blue,
  brightness: Brightness.light,
  textTheme: textTheme);

final ThemeData darkTheme = ThemeData(
  primarySwatch: Colors.blue,
  brightness: Brightness.dark,
  textTheme: textTheme);

final List<Color> colorPallete = <Color>[
  Colors.blue,
  Colors.red,
  Colors.green,
  Colors.orange,
  Colors.cyan,
  Colors.lightBlue,
  Colors.lightGreen,
  Colors.purple,
  Colors.indigo,
  Colors.teal,
  Colors.amber
];


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GasconChat',
      // theme: myTheme,
      // darkTheme: darkTheme,
      // themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
