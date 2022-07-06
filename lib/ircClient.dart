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
    // "Primary" IRC class
    client = Client(config);

   // // Register an onReady event handler
   // client.onReady.listen((event) {
   //   // Join a channel
   //   event.join("#romanian");
   // });

    client.onClientJoin.listen((event) async {
      var lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
      // Loop sending messages
      stdout.write(">> ");
      await for (final l in lines) {
        client.sendMessage("#romanian", l);
        stdout.write(">> ");
      }
    });

    // Register an onMessage event handler
    client.onMessage.listen((event) {
      // Log any message events to the console
      print("<${event.target!.name}><${event.from?.name}> ${event.message}");
      stdout.write(">> ");
    });
    connected = true;

    // Connect to the server
    await client.connect();
  }

  static final IrcClient _instance = IrcClient._privateConstructor();

  factory IrcClient() {
    return _instance;
  }

}
