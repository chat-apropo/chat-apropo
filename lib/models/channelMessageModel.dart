class ChannelMessage {
  String text;
  String sender;
  bool isMine;
  DateTime? timestamp;
  ChannelMessage({required this.text, required this.sender, this.isMine=false, this.timestamp}) {
    timestamp ??= DateTime.now();
  }

  get date => timestamp!;
}
