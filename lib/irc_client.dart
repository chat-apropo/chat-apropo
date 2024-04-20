// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import "package:irc/client.dart";

// Project imports:
import 'package:chat_apropo/models/channel_message_model.dart';
import 'package:chat_apropo/models/dbhelpers.dart';

// Singleton irc client
class IrcClient {
  IrcClient._privateConstructor();
  final dbHelper = DbHelper();

  // This stores our configuration for this client
  bool connected = false;
  bool isConnecting = false;
  bool loggedIn = false;
  bool isLoggingIn = false;
  late Client client;

  // Observer hashmap
  Map<String, StreamSubscription> observers = {};

  connect() async {
    if (isConnecting) {
      return;
    }
    isConnecting = true;
    var account = await dbHelper.account();
    var nickname = "";
    if (account == null) {
      nickname = "flutterAppGuest";
    } else {
      nickname = account.nickname;
    }

    var config = Configuration(
      host: "irc.dot.org.es",
      port: 6667,
      ssl: false,
      nickname: nickname,
      username: nickname,
      realname: "Flutter App",
    );

    client = Client(config);
    connected = true;
    debugPrint("Connecting to ${config.host}:${config.port}");

    // Connect to the server
    await client.connect();

    if (account != null) {
      debugPrint(await login(account));
    }

    // Message arrived
    subscribe("dbHandlerMessageCapture", client.onMessage,
        (MessageEvent event) async {
      debugPrint(
          "<${event.target!.name}><${event.from?.name}> ${event.message}");
      var message = ChannelMessage(
        text: event.message ?? "",
        sender: event.from?.name ?? "--",
        channel: event.target!.name ?? "--",
      );
      dbHelper.addMessage(message);
    });

    isConnecting = false;
  }

  Future<String?> register(Account account) async {
    if (!connected) {
      return "Irc client is not connected";
    }
    String nickname = account.nickname;
    String password = account.password;
    client.changeNickname(nickname);
    client.sendMessage("nickserv", "register $password");
    String? message;
    try {
      await for (final event
          in client.onNotice.timeout(const Duration(seconds: 5))) {
        var response = event.message!
            .replaceAll(RegExp(r"\s+"), " ")
            .replaceAll(RegExp(r"\u0002"), "")
            .toLowerCase();
        var fromNick = event.from!.name!.toLowerCase();
        if (fromNick == 'nickserv') {
          if (response.contains('is already registered')) {
            message = "Nickname is already registered";
            break;
          }
          if (response
              .contains('nickname ${nickname.toLowerCase()} registered')) {
            message = null;
            break;
          }
        }
      }
    } on TimeoutException {
      message = "Registration Timeout";
    }
    return message;
  }

  Future<String?> login(Account account) async {
    if (isLoggingIn) {
      return "Already logging in";
    }
    isLoggingIn = true;
    if (!connected) {
      return "Irc client is not connected";
    }
    String nickname = account.nickname;
    String password = account.password;
    client.changeNickname(nickname);
    client.sendMessage("nickserv", "identify $password");
    var resent = false;
    String? message;
    try {
      await for (final event
          in client.onNotice.timeout(const Duration(seconds: 5))) {
        var response = event.message!.toLowerCase();
        var fromNick = event.from!.name!.toLowerCase();
        debugPrint("Waiting for login: $response");

        if (fromNick == 'nickserv') {
          if (response.contains('you are now recognized')) {
            message = null;
            break;
          } else if (!resent) {
            client.sendMessage("nickserv", "identify $password");
            resent = true;
          }
        }
      }
    } on TimeoutException {
      message = "Login Timeout";
    }

    isLoggingIn = false;
    return message;
  }

  static final IrcClient _instance = IrcClient._privateConstructor();

  factory IrcClient() {
    return _instance;
  }

  bool subscribe<T>(String identifier, Stream<T> stream, Function(T) callback) {
    if (observers.containsKey(identifier)) {
      return false;
    }
    observers[identifier] = stream.listen(callback);
    return true;
  }

  Future<bool> unsubscribe(String identifier) async {
    if (!observers.containsKey(identifier)) {
      return false;
    }
    await observers[identifier]!.cancel();
    observers.remove(identifier);
    return true;
  }
}
