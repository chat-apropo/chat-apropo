import 'package:chat_apropo/i18n.dart';
import 'package:chat_apropo/models/channelMessageModel.dart';
import 'package:flutter/material.dart';

import '../models/chanModel.dart';
import '../utils.dart';
import '../widgets/conversationList.dart';

class ChanPage extends StatefulWidget {
  const ChanPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ChanPageState createState() => _ChanPageState();
}

class _ChanPageState extends State<ChanPage> {
  List<Channel> channels = [
    Channel(
      name: "#romanian",
      lastMessage: ChannelMessage(
          text: "Last message here",
          sender: "John",
          timestamp: DateTime.now(),
          isMine: false),
    ),
    Channel(
      name: "#bots",
      lastMessage: ChannelMessage(
          text: "Last message here",
          sender: "John",
          timestamp: DateTime.now(),
          isMine: false),
    ),
    Channel(
      name: "#radio",
      lastMessage: ChannelMessage(
          text: "Last message here",
          sender: "John",
          timestamp: DateTime.now(),
          isMine: false),
    ),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Conversations".i18n,
                      style:
                          const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.only(
                          left: 8, right: 8, top: 2, bottom: 2),
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.pink[50],
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.add,
                            color: Colors.pink,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 2,
                          ),
                          Text(
                            "Add New".i18n,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search...".i18n,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.all(8),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade100)),
                ),
              ),
            ),
            ListView.builder(
              itemCount: channels.length,
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 16),
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return ConversationList(
                  name: channels[index].name,
                  isChannelList: true,
                  messageText: channels[index].lastMessage?.text ?? "",
                  color: nickColor(channels[index].name),
                  time: datetimeToString(channels[index].lastMessage?.date),
                  isMessageRead: (index == 0 || index == 3) ? true : false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
