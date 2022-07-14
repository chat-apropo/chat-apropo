import 'package:chat_apropo/models/chanModel.dart';
import 'package:chat_apropo/models/channelMessageModel.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const dbFilename = 'messages.db';
const dbVersion = 1;

Future createMessageTables(db, version) async {
  await db.execute('''
    PRAGMA foreign_keys = ON;
    CREATE TABLE IF NOT EXISTS channels (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      isPm INTEGER DEFAULT 0 NOT NULL,
    );
    CREATE TABLE IF NOT EXISTS messages (
      id INTEGER PRIMARY KEY,
      seqId INTEGER NOT NULL,
      message TEXT NOT NULL,
      sender TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      channelId INTEGER NOT NULL,
      FOREIGN KEY (channelId) REFERENCES channels(id)
    );
  ''');
}


/// Creates the database if it doesn't exist.
Future ensureDatabaseCreated() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbPath = await getDatabasesPath();
  debugPrint("Creating/Using database at $dbPath/$dbFilename");
  openDatabase(
    join(dbPath, dbFilename),
    onCreate: createMessageTables,
    version: dbVersion,
  );
}

class DbChannel {
  final int id;
  final String name;
  final int isPm;
  final int updated;

  const DbChannel({
    required this.id,
    required this.name,
    required this.isPm,
    required this.updated,
  });
}

class DbMessage {
  final int id;
  final int seqId;
  final String message;
  final String sender;
  final int timestamp;
  final int channelId;

  const DbMessage({
    required this.id,
    required this.seqId,
    required this.message,
    required this.sender,
    required this.timestamp,
    required this.channelId,
  });
}

/// Singleton wrapper around database
class DbHelper {
  DbHelper._privateConstructor();

  static final DbHelper _instance = DbHelper._privateConstructor();

  factory DbHelper() {
    return _instance;
  }

  static Database? _db;

  /// Gets database singleton
  Future<Database> open() async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  /// Gracefully closes the database.
  Future dispose() async {
    await _db!.close();
    _db = null;
  }

  /// Initializes the database.
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbFilename);
    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: createMessageTables,
    );
  }

  /// Inserts a new channel
  Future insertChannel(Channel channel) async {
    Map<String, dynamic> data = {
      'name': channel.name,
      'isPm': channel.name.startsWith("#") ? 0 : 1,
    };
    await _db!.insert('channels', data);
  }

}
