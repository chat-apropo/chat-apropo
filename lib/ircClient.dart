import 'dart:async';

import 'package:chat_apropo/models/dbhelpers.dart';
import "package:irc/client.dart";

// Singleton irc client
class IrcClient {
  IrcClient._privateConstructor();

  // This stores our configuration for this client
  bool connected = false;
  bool loggedIn = false;
  late Client client;

  connect() async {
    var dbHelpers = DbHelper();
    var account = await dbHelpers.account();
    var nickname = "";
    if (account == null) {
      nickname = "flutterAppGuest";
    } else {
      nickname = account.nickname;
    }

    var config = Configuration(
        host: "irc.dot.org.es",
        port: 6697,
        ssl: true,
        nickname: nickname,
        username: nickname);

    client = Client(config);
    connected = true;

    // Connect to the server
    await client.connect();
  }

  Future<String?> register(String nickname, String password) async {
    if (!connected) {
      return "Irc client is not connected";
    }
    client.changeNickname(nickname);
    client.sendMessage("nickserv", "register $password");
    String? message;
    try {
      await for (final event
          in client.onNotice.timeout(const Duration(seconds: 5))) {
        var response = event.message!.toLowerCase();
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
    } on TimeoutException catch (e) {
      message = "Registration Timeout";
    }
    return message;
  }

  Future<String?> login(String nickname, String password) async {
    if (!connected) {
      return "Irc client is not connected";
    }
    client.changeNickname(nickname);
    client.sendMessage("nickserv", "identify $password");
    String? message;
    try {
      await for (final event
          in client.onNotice.timeout(const Duration(seconds: 5))) {
        var response = event.message!.toLowerCase();
        var fromNick = event.from!.name!.toLowerCase();
        if (fromNick == 'nickserv') {
          if (response.contains('you are now recognized')) {
            message = null;
            break;
          }
        }
      }
    } on TimeoutException catch (e) {
      message = "Login Timeout";
    }
    return message;
  }

  static final IrcClient _instance = IrcClient._privateConstructor();

  factory IrcClient() {
    return _instance;
  }
}
