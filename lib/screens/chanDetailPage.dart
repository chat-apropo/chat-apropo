import 'package:flutter/material.dart';
import 'package:gasconchat/ircClient.dart';
import 'package:gasconchat/models/channelMessageModel.dart';
import 'package:gasconchat/widgets/ircTextMessage.dart';

class ChanDetailPage extends StatefulWidget {
  String channel;
  ChanDetailPage({Key? key, required this.channel}) : super(key: key);

  @override
  ChanDetailPageState createState() => ChanDetailPageState();
}

class ChanDetailPageState extends State<ChanDetailPage> {
  List<ChannelMessage> messages = [];

  var irc = IrcClient();
  final textField = TextEditingController();
  final textFocusNode = FocusNode();
  ScrollController scrollController = ScrollController();
  late String channel;

  void _join() {
    irc.client.join(widget.channel);
  }

  void _part() {
    irc.client.part(widget.channel);
  }

  void scrollDown() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    channel = widget.channel;
    irc.client.onClientJoin.listen((event) {
      setState(() {
        messages.add(
            ChannelMessage(text: "JOINED CHANNEL", sender: widget.channel));
      });
    });

    irc.client.onMessage.listen((event) {
      print("<${event.target!.name}><${event.from?.name}> ${event.message}");

      setState(() {
        if (event.target?.name == widget.channel) {
          messages.add(ChannelMessage(
              text: event.message ?? "", sender: event.from?.name ?? "--"));
        }
      });
    });

    _join();
  }

  void _submit(text) {
    setState(() {
      irc.client.sendMessage(widget.channel, text);
      textField.clear();
      messages.add(ChannelMessage(text: text, sender: "You", isMine: true));
      textFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    // _part();
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(
                  width: 2,
                ),
                const CircleAvatar(
                  backgroundImage: NetworkImage(
                      "<https://randomuser.me/api/portraits/men/5.jpg>"),
                  maxRadius: 20,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        channel,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        "Online",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.settings,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              itemCount: messages.length,
              shrinkWrap: true,
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(top: 10, bottom: 100),
              itemBuilder: (context, index) {
                var message = messages[index];
                return IrcText(message: message);
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.only(left: 10, bottom: 10, top: 10),
              height: 60,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  Expanded(
                    child: TextField(
                      controller: textField,
                      autofocus: true,
                      focusNode: textFocusNode,
                      onSubmitted: _submit,
                      decoration: const InputDecoration(
                          hintText: "Write message...",
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      _submit(textField.text);
                    },
                    backgroundColor: Colors.blue,
                    elevation: 0,
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
