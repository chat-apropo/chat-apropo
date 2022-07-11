import 'dart:convert';

import "package:irc/client.dart";
import "dart:io";

// Singleton irc client
class IrcClient {
  IrcClient._privateConstructor();

  // This stores our configuration for this client
  var config = Configuration(
      host: "irc.dot.org.es",
      port: 6697,
      ssl: true,
      nickname: "flutterApp",
      username: "flutterApp");

  bool connected = false;
  late Client client;

  connect() async {
    client = Client(config);
    connected = true;

    // Connect to the server
    await client.connect();
  }

  static final IrcClient _instance = IrcClient._privateConstructor();

  factory IrcClient() {
    return _instance;
  }

}
