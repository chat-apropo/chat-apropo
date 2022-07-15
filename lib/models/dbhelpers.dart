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
      name TEXT NOT NULL UNIQUE,
      lastMessage INTEGER,
      FOREIGN KEY(lastMessage) REFERENCES messages(id)
    );
    CREATE TABLE IF NOT EXISTS messages (
      id INTEGER PRIMARY KEY,
      seqId INTEGER NOT NULL,
      message TEXT NOT NULL,
      sender TEXT NOT NULL,
      isMine INTEGER,
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
  final int updated;

  const DbChannel({
    required this.id,
    required this.name,
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
  Future<int> insertChannel(Channel channel) async {
    Map<String, dynamic> data = {
      'name': channel.name,
    };
    return await _db!.insert('channels', data);
  }

  Future<int?> _getChannelId(String channeName) async {
    final channel = await _db!
        .query('channels', where: 'name = ?', whereArgs: [channeName]);
    if (channel.isEmpty) return null;
    return channel.first['id'] as int;
  }

  Future<int> _lastMessageSeqId(int channelId) async {
    final message = await _db!.query('messages',
        where: 'channelId = ?', whereArgs: [channelId], orderBy: 'seqId DESC');
    if (message.isEmpty) return 0;
    return message.first['seqId'] as int;
  }

  /// Gets chunk of messages from a channel
  Future<List<ChannelMessage>> messages(
      String channeName, int start, int end) async {
    final db = _db!;
    final channelId = await _getChannelId(channeName);

    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'channelId = ? AND seqId >= ? AND seqId <= ?',
      whereArgs: [channelId, start, end],
      orderBy: 'seqId ASC',
    );

    return List.generate(maps.length, (i) {
      return ChannelMessage(
        text: maps[i]['message'],
        sender: maps[i]['sender'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
      );
    });
  }

  /// Returns the last message of a channel
  Future<ChannelMessage?> lastMessage(String channeName) async {
    final db = _db!;
    final channelId = await _getChannelId(channeName);
    if (channelId == null) {
      return null;
    }
    final seqId = await _lastMessageSeqId(channelId);
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'channelId = ? AND seqId = ?',
      whereArgs: [channelId, seqId],
      orderBy: 'seqId DESC',
    );
    return ChannelMessage(
      text: maps.first['message'],
      sender: maps.first['sender'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(maps.first['timestamp']),
    );
  }

  /// Gets a message
  Future<ChannelMessage> _getMessage(int id) async {
    final db = _db!;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
    return ChannelMessage(
      text: maps.first['message'],
      sender: maps.first['sender'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(maps.first['timestamp']),
    );
  }

  /// Gets all channels
  Future<List<Channel>> channels() async {
    final List<Map<String, dynamic>> maps = await _db!.query('channels');
    List<Channel> channels = [];
    for (final map in maps) {
      final message = await _getMessage(map['lastMessage']);
      channels.add(Channel(
        name: map['name'],
        lastMessage: message,
      ));
    }
    return channels;
  }

  /// Inserts a new message
  /// Updates the channels lastMessage
  /// Inserts the channel if it doesn't exist
  Future<int> insertMessage(String channelName, ChannelMessage message,
      [bool isMine = false]) async {
    final db = _db!;
    var channelId = await _getChannelId(channelName);
    channelId ??= await insertChannel(Channel(name: channelName));
    final lastMessageSeqId = await _lastMessageSeqId(channelId);
    final data = {
      'message': message.text,
      'sender': message.sender,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'channelId': channelId,
      'isMine': isMine ? 1 : 0,
      'seqId': lastMessageSeqId + 1,
    };
    final messageId = await db.insert('messages', data);
    await db.update('channels', {'lastMessage': messageId},
        where: 'id = ?', whereArgs: [channelId]);
    return messageId;
  }
}
