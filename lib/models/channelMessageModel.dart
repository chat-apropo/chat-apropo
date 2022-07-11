class ChannelMessage {
  String text;
  String sender;
  bool isMine;
  ChannelMessage({required this.text, required this.sender, this.isMine=false});
}
