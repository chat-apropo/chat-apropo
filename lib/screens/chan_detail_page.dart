// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Package imports:
import 'package:any_link_preview/any_link_preview.dart';

// Project imports:
import 'package:chat_apropo/i18n.dart';
import 'package:chat_apropo/irc_client.dart';
import 'package:chat_apropo/models/channel_message_model.dart';
import 'package:chat_apropo/models/dbhelpers.dart';
import 'package:chat_apropo/widgets/irc_text_message.dart';
import '../widgets/audio_player.dart';
import '../widgets/upload_fab_menu.dart';

// Number of pixels to scroll up by to show the go to bottom button
const showScrolldownButtonWhenScolledUpBy = 400;
const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
const videoExtensions = ['mp4', 'mov', 'avi', 'flv', 'wmv', 'mpg', 'mpeg'];
const audioExtensions = ['mp3', 'wav', 'ogg', 'flac', 'aac', 'wma'];
const collapseMessageMinInterval = Duration(seconds: 5);
const updateTimestampsInterval = Duration(seconds: 10);
const loadMessagesChunkSize = 100;

enum UrlType {
  image,
  video,
  audio,
  other,
}

bool isDirectlyPreviewable(List<String> extensionList, String url) {
  return extensionList.contains(url.split('.').last);
}

bool isImage(String url) {
  return isDirectlyPreviewable(imageExtensions, url);
}

bool isVideo(String url) {
  return isDirectlyPreviewable(videoExtensions, url);
}

bool isAudio(String url) {
  return isDirectlyPreviewable(audioExtensions, url);
}

UrlType getUrlType(String url) {
  if (isImage(url)) {
    return UrlType.image;
  } else if (isVideo(url)) {
    return UrlType.video;
  } else if (isAudio(url)) {
    return UrlType.audio;
  } else {
    return UrlType.other;
  }
}

String? findUrlInText(String text) {
  final RegExp urlRegExp = RegExp(
      r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");
  final RegExpMatch? match = urlRegExp.firstMatch(text);
  if (match != null) {
    return match.group(0);
  }
  return null;
}

bool _getUrlValid(String url) {
  bool isUrlValid = AnyLinkPreview.isValidLink(
    url,
    protocols: ['http', 'https'],
  );
  return isUrlValid;
}

class ChanDetailPage extends StatefulWidget {
  final String channel;
  const ChanDetailPage({Key? key, required this.channel}) : super(key: key);

  @override
  ChanDetailPageState createState() => ChanDetailPageState();
}

class ChanDetailPageState extends State<ChanDetailPage> {
  final dbHelper = DbHelper();

  // Load from db
  List<ChannelMessage> messages = [];

  var irc = IrcClient();
  bool showGoToBottomButton = false;
  final textField = TextEditingController();
  final textFocusNode = FocusNode();
  ScrollController scrollController = ScrollController();
  late String channel;
  bool isSendMenuVisible = false;
  bool mergeMessageBubble = false;
  late String accumulatedMessage;
  late Timer _updateTimestampsTimer;

  void _join() {
    irc.client.join(widget.channel);
  }

  // ignore: unused_element
  void _part() {
    irc.client.part(widget.channel);
  }

  void scrollDown() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 800,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    channel = widget.channel;

    // Joined channel
    irc.client.onClientJoin.listen((event) {
      setState(() {
        messages.add(ChannelMessage(
            text: "JOINED CHANNEL".i18n,
            sender: widget.channel,
            channel: channel));
      });
    });

    // Message arrived
    irc.client.onMessage.listen((event) async {
      debugPrint(
          "<${event.target!.name}><${event.from?.name}> ${event.message}");

      // TODO background service populating all messages for all joined channels database
      if (event.target?.name != widget.channel) {
        return;
      }
      var message = ChannelMessage(
          text: event.message ?? "",
          sender: event.from?.name ?? "--",
          channel: widget.channel);
      dbHelper.addMessage(message);
      setState(() {
        messages.add(message);

        var pos = scrollController.position.pixels;
        var distanceToBottom = scrollController.position.maxScrollExtent - pos;
        if (!showGoToBottomButton ||
            distanceToBottom < showScrolldownButtonWhenScolledUpBy) {
          scrollDown();
        }
      });
    });

    _join();

    // Updates timestamps
    _updateTimestampsTimer =
        Timer.periodic(updateTimestampsInterval, (Timer t) {
      setState(() {});
    });

    _populateMessages();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 10),
        curve: Curves.easeOut,
      );
    });
  }

  Future _populateMessages() async {
    await _loadMessages();
  }

  // Load loadMessagesChunkSize messages from db
  Future _loadMessages([int row = 0]) async {
    if (row == 0) {
      messages = await dbHelper.messages(channel, loadMessagesChunkSize);
    } else {
      // TODO load more messages
      messages = await dbHelper.messages(channel, loadMessagesChunkSize);
    }
    setState(() {});
  }

  Future _submit(String text) async {
    // if text is whitespace or empty, do nothing
    if (text.trim().isNotEmpty) {
      irc.client.sendMessage(widget.channel, text);
      textField.clear();
      var message = ChannelMessage(
        text: text,
        sender: irc.client.nickname ?? "You",
        channel: widget.channel,
        isMine: true,
      );
      messages.add(message);
      setState(() {});
      textFocusNode.requestFocus();

      dbHelper.addMessage(message);
    }
    scrollDown();
  }

  @override
  void dispose() {
    textFocusNode.dispose();
    _updateTimestampsTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Visibility(
        visible: showGoToBottomButton,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 120.0),
          child: Visibility(
            visible: !isSendMenuVisible,
            child: FloatingActionButton(
              onPressed: scrollDown,
              child: const Icon(Icons.arrow_downward),
            ),
          ),
        ),
      ),
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
                IconButton(
                  onPressed: () {
                    setState(() {
                      debugPrint(i18nKeys.toString());
                    });
                  },
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          NotificationListener(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                var pos = scrollController.position.pixels;
                var distanceToBottom =
                    scrollController.position.maxScrollExtent - pos;
                setState(() {
                  showGoToBottomButton =
                      distanceToBottom > showScrolldownButtonWhenScolledUpBy;
                });
              }
              return false;
            },
            child: ListView.builder(
              itemCount: messages.length,
              shrinkWrap: true,
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(top: 10, bottom: 100),
              itemBuilder: (context, index) {
                if (index == 0) {
                  mergeMessageBubble = false;
                }
                // Find current and next message
                var message = messages[index];
                var nextMessage =
                    index + 1 < messages.length ? messages[index + 1] : null;

                if (!mergeMessageBubble) {
                  accumulatedMessage = message.text;
                } else {
                  accumulatedMessage += "\n${message.text}";
                }

                // Reset collapsing state and send a preview if url
                var url = findUrlInText(message.text);
                if (url != null && _getUrlValid(url)) {
                  mergeMessageBubble = false;
                  return _messageWithUrlPreview(message, url);
                }

                final timeDelta = message.timestamp!
                    .difference(nextMessage?.timestamp ?? DateTime.now())
                    .abs();

                // Check for collapsing into single bubble
                mergeMessageBubble = nextMessage != null &&
                    nextMessage.sender == message.sender &&
                    timeDelta < collapseMessageMinInterval;

                // Make message bubble or nothing if colapsing
                if (mergeMessageBubble) {
                  return Container();
                }
                return IrcText(
                    message: ChannelMessage.fromMessage(
                        message, accumulatedMessage));
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
                  const SizedBox(
                    width: 60,
                  ),
                  Expanded(
                    child: TextField(
                      controller: textField,
                      autofocus: true,
                      focusNode: textFocusNode,
                      onSubmitted: _submit,
                      decoration: InputDecoration(
                          hintText: "Write message...".i18n,
                          hintStyle: const TextStyle(color: Colors.black54),
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
          Positioned(
            bottom: 0,
            left: 0,
            child: FabSendMenu(
              bottom: 15,
              left: 25,
              onToggle: (bool isOpen) {
                setState(() {
                  isSendMenuVisible = isOpen;
                });
              },
              onSend: (String text) {
                _submit(text);
              },
            ),
          ),
        ],
      ),
    );
  }

  Column _messageWithUrlPreview(ChannelMessage message, String url) {
    final accmessage = ChannelMessage.fromMessage(message, accumulatedMessage);
    switch (getUrlType(url)) {
      case UrlType.audio:
        return Column(children: [
          IrcText(
            message: accmessage,
            child: AudioPlayerWidget(url: url),
          ),
        ]);
      case UrlType.video:
        return Column(children: [
          IrcText(
            message: accmessage,
          ),
        ]);
      case UrlType.image:
        return Column(children: [
          IrcText(
            message: accmessage,
            child: Image.network(
              url,
              width: 400,
              fit: BoxFit.cover,
            ),
          ),
        ]);
      default:
        return Column(
          children: [
            IrcText(
              message: accmessage,
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: AnyLinkPreview(
                link: url,
                displayDirection: UIDirection.uiDirectionHorizontal,
                showMultimedia: true,
                bodyMaxLines: 5,
                bodyTextOverflow: TextOverflow.ellipsis,
                titleStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                bodyStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        );
    }
  }
}
