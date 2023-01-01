import 'dart:collection';
import 'dart:io';

import 'package:chat_apropo/models/chanModel.dart';
import 'package:chat_apropo/models/channelMessageModel.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const dbFilename = 'messages.db';
const dbVersion = 1;

enum Theme { light, dark, system }

/// Config data class
class Config {
  final Theme theme;
  final String language;
  const Config({
    required this.theme,
    required this.language,
  });
}

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
      seqId INTEGER NOT NULL UNIQUE,
      message TEXT NOT NULL,
      sender TEXT NOT NULL,
      isMine INTEGER,
      timestamp INTEGER NOT NULL,
      channelId INTEGER NOT NULL,
      FOREIGN KEY (channelId) REFERENCES channels(id)
    );
    CREATE TABLE IF NOT EXISTS config (
      id INTEGER PRIMARY KEY,
      language TEXT NOT NULL,
      theme INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS account (
      id INTEGER PRIMARY KEY,
      nickname TEXT NOT NULL,
      password TEXT NOT NULL
    );
  ''');

  final String defaultLocale = Platform.localeName.split('_').first;
  debugPrint("System language: $defaultLocale");
  await db.rawInsert(
    '''
    INSERT INTO config (language, theme) VALUES (?, ?);
  ''',
    [defaultLocale, Theme.system.index],
  );
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

class MessageQueueItem {
  final String channelName;
  final ChannelMessage message;

  MessageQueueItem({required this.channelName, required this.message});
}

class Account {
  final String nickname;
  final String password;

  Account({required this.nickname, required this.password});
}

/// Singleton wrapper around database
class DbHelper {
  DbHelper._privateConstructor();
  final _messageQueue = Queue<MessageQueueItem>();
  bool _messageQueueRunning = false;

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

  /// Return config Map
  Future<Config> getConfig() async {
    final db = _db!;
    final Map<String, dynamic> config = (await db.query('config')).first;
    return Config(
      theme: Theme.values[config['theme']],
      language: config['language'],
    );
  }

  /// Update config Map
  Future<void> updateConfig(Config config) async {
    final db = _db!;
    await db.update('config', {
      'language': config.language,
      'theme': config.theme.index,
    });
  }

  /// Inserts a new channel
  Future<int> insertChannel(Channel channel) async {
    Map<String, dynamic> data = {
      'name': channel.name,
    };
    return await _db!.insert('channels', data);
  }

  Future<String?> _getChannelName(int channelId) async {
    final db = _db!;
    final List<Map<String, dynamic>> channel = await db.query(
      'channels',
      where: 'id = ?',
      whereArgs: [channelId],
    );
    if (channel.isEmpty) return null;
    return channel.first['name'];
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
  /// If end is not passed, it will return the last START messages
  Future<List<ChannelMessage>> messages(String channelName, int start,
      [int end = -1]) async {
    final db = _db!;
    final channelId = await _getChannelId(channelName);

    if (channelId == null) return [];

    List<Map<String, dynamic>> maps;
    if (end > -1) {
      maps = await db.query(
        'messages',
        where: 'channelId = ? AND seqId >= ? AND seqId <= ?',
        whereArgs: [channelId, start, end],
        orderBy: 'seqId DESC',
      );
    } else {
      maps = await db.query(
        'messages',
        where: 'channelId = ?',
        whereArgs: [channelId],
        orderBy: 'seqId DESC',
        limit: start,
      );
    }
    maps = maps.reversed.toList();

    return List.generate(maps.length, (i) {
      return ChannelMessage(
        text: maps[i]['message'],
        sender: maps[i]['sender'],
        channel: channelName,
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
        isMine: maps[i]['isMine'] == 1,
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
      channel: channeName,
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
    final channelName = await _getChannelName(maps.first['channelId'] as int);
    if (channelName == null) {
      throw Exception('Channel not found');
    }
    return ChannelMessage(
      text: maps.first['message'],
      sender: maps.first['sender'],
      channel: channelName,
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
  Future<int> insertMessage(String channelName, ChannelMessage message) async {
    final db = _db!;
    var channelId = await _getChannelId(channelName);
    channelId ??= await insertChannel(Channel(name: channelName));
    final lastMessageSeqId = await _lastMessageSeqId(channelId);
    final data = {
      'message': message.text,
      'sender': message.sender,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'channelId': channelId,
      'isMine': message.isMine ? 1 : 0,
      'seqId': lastMessageSeqId + 1,
    };
    final messageId = await db.insert('messages', data);
    await db.update('channels', {'lastMessage': messageId},
        where: 'id = ?', whereArgs: [channelId]);
    return messageId;
  }

  /// Adds message to insert to queue
  /// It is important to add messages only using this method to avoid duplicated seqids
  void addMessage(ChannelMessage message) {
    _messageQueue.add(
      MessageQueueItem(
        channelName: message.channel,
        message: message,
      ),
    );
    _processQueue();
  }

  /// Processes the message queue
  Future _processQueue() async {
    if (_messageQueueRunning) return;
    await __processQueue();
  }

  Future __processQueue() async {
    if (_messageQueue.isEmpty) return;
    _messageQueueRunning = true;
    final item = _messageQueue.first;
    await insertMessage(item.channelName, item.message);
    _messageQueue.removeFirst();
    await __processQueue();
    _messageQueueRunning = false;
  }

  /// Saves user account
  Future<void> saveAccount(Account account) async {
    final db = _db!;
    final data = {
      "nickname": account.nickname,
      "password": account.password,
    };
    await db.insert('account', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Retrieves the user account
  Future<Account?> account() async {
    final List<Map<String, dynamic>> maps = await _db!.query('account');
    if (maps.isEmpty) return null;
    // TODO manage multiple accounts?
    return Account(
      nickname: maps.last['nickname'],
      password: maps.last['password'],
    );
  }
}
