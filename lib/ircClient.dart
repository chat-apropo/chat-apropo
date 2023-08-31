// Dart imports:
import 'dart:async';

// Package imports:
import "package:irc/client.dart";

// Project imports:
import 'package:chat_apropo/models/dbhelpers.dart';

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

    if (account != null) {
      await login(account);
    }
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

        if (fromNick == 'nickserv') {
          print("NICKSERV: $response");
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
    return message;
  }

  static final IrcClient _instance = IrcClient._privateConstructor();

  factory IrcClient() {
    return _instance;
  }
}
