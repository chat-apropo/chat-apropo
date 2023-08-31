// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Project imports:
import 'package:chat_apropo/models/dbhelpers.dart';
import 'package:chat_apropo/screens/register_page.dart';
import 'i18n.dart';
import 'screens/homePage.dart';

const baseFontSize = 14.0;

const textTheme = TextTheme(
    bodyLarge: TextStyle(fontSize: baseFontSize, color: Colors.green),
    displayLarge: TextStyle(fontSize: baseFontSize + 4));

final ThemeData myTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    textTheme: textTheme);

final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    textTheme: textTheme);

void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
  }
  databaseFactory = databaseFactoryFfi;
  ensureDatabaseCreated();

  var dbHelper = DbHelper();
  await dbHelper.open();
  await i18nLoad();
  i18nSetLanguage((await dbHelper.getConfig()).language);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    var dbHelper = DbHelper();

    return MaterialApp(
      title: 'GasconChat',
      theme: myTheme,
      // darkTheme: darkTheme,
      // themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      // home: const HomePage(),
      home: FutureBuilder(
          future: dbHelper.account(),
          builder: (BuildContext context, AsyncSnapshot<Account?> snapshot) {
            // data loaded:
            var account = snapshot.data;
            if (account == null) {
              return const SignUpScreen();
            } else {
              return HomePage(account: account);
            }
          }),
    );
  }
}
