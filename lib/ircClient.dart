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

  static final IrcClient _instance = IrcClient._privateConstructor();

  factory IrcClient() {
    return _instance;
  }
}
