// Project imports:
import 'package:chat_apropo/models/channel_message_model.dart';

class Channel {
  String name;
  ChannelMessage? lastMessage;
  Channel({
    required this.name,
    this.lastMessage,
  });
}
