// Project imports:
import 'package:chat_apropo/models/channelMessageModel.dart';

class Channel {
  String name;
  ChannelMessage? lastMessage;
  Channel({
    required this.name,
    this.lastMessage,
  });
}
