import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const dbFilename = 'messages.db';

Future createMessageTables(db, version) async {
  await db.execute('''
    PRAGMA foreign_keys = ON;
    CREATE TABLE IF NOT EXISTS channels (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      isPm INTEGER,
      updated INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS messages (
      id INTEGER PRIMARY KEY,
      seqId INTEGER NOT NULL,
      message TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      channelId INTEGER NOT NULL,
      FOREIGN KEY (channelId) REFERENCES channels(id)
    );
  ''');
}


Future ensureDatabaseCreated() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbPath = await getDatabasesPath();
  debugPrint("Creating/Using database at $dbPath/$dbFilename");
  openDatabase(
    join(dbPath, dbFilename),
    onCreate: createMessageTables,
    version: 1,
  );
}
