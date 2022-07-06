import 'package:flutter/cupertino.dart';

class ChannelMessage {
  String message;
  String sender;
  bool isMine;
  ChannelMessage({required this.message, required this.sender, this.isMine=false});
}
