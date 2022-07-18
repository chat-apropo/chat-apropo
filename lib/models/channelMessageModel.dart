class ChannelMessage {
  late String text;
  late String sender;
  late bool isMine;
  DateTime? timestamp;
  ChannelMessage({required this.text, required this.sender, this.isMine=false, this.timestamp}) {
    timestamp ??= DateTime.now();
  }

  // Contructor for creating from another message and changing the message
  ChannelMessage.fromMessage(ChannelMessage message, String? newText) {
    text = newText ?? message.text;
    sender = message.sender;
    isMine = message.isMine;
    timestamp = message.timestamp ?? DateTime.now();
  }

  get date => timestamp!;
}
