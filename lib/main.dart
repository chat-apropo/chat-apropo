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

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    return MaterialApp(
      title: 'Chat Apropo',
      theme: myTheme,
      // darkTheme: darkTheme,
      // themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
