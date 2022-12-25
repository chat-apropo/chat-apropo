import 'package:chat_apropo/ircClient.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/channelMessageModel.dart';
import '../utils.dart';

final RegExp regIgnoreChars = RegExp(r""",|\.|;|'|@|"|\*|\?|""");
final regUrl = RegExp(
    r'((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+(?:[.][a-z]{2,4})+/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'
    "''"
    '".,<>?«»“”‘’]))',
    caseSensitive: false,
    multiLine: false);

const boldEscape = '\x02';
const italicEscape = '\x1D';
const underlineEscape = '\x1F';

class ColorAndSize {
  Color? color;
  int size;

  ColorAndSize(this.color, this.size);
}

class IrcColors {
  static var escape = String.fromCharCode(0x03);
  static const white = "00";
  static const black = "01";
  static const navy = "02";
  static const green = "03";
  static const red = "04";
  static const maroon = "05";
  static const purple = "06";
  static const orange = "07";
  static const yellow = "08";
  static const lightGreen = "09";
  static const teal = "10";
  static const cyan = "11";
  static const blue = "12";
  static const magenta = "13";
  static const gray = "14";
  static const lightGray = "15";
  static const defaultColor = Colors.black;

  static Map<String, Color> colors = {
    white: Colors.white,
    black: Colors.black,
    navy: Colors.blue,
    green: Colors.green,
    red: Colors.red,
    maroon: Colors.brown,
    purple: Colors.purple,
    orange: Colors.orange,
    yellow: Colors.yellow,
    lightGreen: Colors.lightGreen,
    teal: Colors.teal,
    cyan: Colors.cyan,
    blue: Colors.blue,
    magenta: Colors.pink,
    gray: Colors.grey,
    lightGray: Colors.white10,
  };

  static Color? getColor(String color) {
    if (colors.containsKey(color)) {
      return colors[color]!;
    } else {
      return null;
    }
  }
}

// Message Box
class IrcText extends StatelessWidget {
  final ChannelMessage message;
  final Widget? child;
  const IrcText({
    Key? key,
    required this.message,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String nickname =
        message.sender.toLowerCase().replaceAll(regIgnoreChars, "");
    final color = nickColor(nickname);

    // HACK TODO coudln't manage to align sender without adding spaces around it
    // Get longest line
    final longestLine = message.text.split("\n").reduce(
          (a, b) => a.length > b.length ? a : b,
        );
    // Create spaces for each character minus sender length
    final width = longestLine.length - nickname.length;
    var spaces = "";
    if (width > 0) {
      spaces = List<String>.generate((width * 1.5).ceil(), (i) => " ").join();
    }
    final sender = message.isMine
        ? "$spaces${message.sender}"
        : "${message.sender}$spaces";

    List<Widget> bodyWidgets = [
      SelectableText.rich(
        TextSpan(
          children: [
            WidgetSpan(
              child: Text(
                sender,
                style: TextStyle(
                  color: !message.isMine ? color : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const TextSpan(
              text: "\n",
            ),
            ...buildTextSpan(context, message),
          ],
        ),
      ),
    ];

    if (child != null) {
      bodyWidgets.add(
        const SizedBox(height: 25),
      );
      bodyWidgets.add(child!);
    }

    return Container(
      padding: const EdgeInsets.only(
        left: 14,
        right: 14,
        top: 10,
        bottom: 10,
      ),
      child: Align(
        alignment: (!message.isMine ? Alignment.topLeft : Alignment.topRight),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: (!message.isMine ? Colors.grey[200] : Colors.blue[200]),
            border: Border.all(
              color: color,
              width: (message.isMine ? 0 : 3),
            ),
          ),
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: 10,
                  bottom: 5,
                ),
                child: Column(
                  crossAxisAlignment: (!message.isMine
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end),
                  children: bodyWidgets,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      showToast(context,
          "Could not open the url. Make sure you've allowed the app to open links.");
    }
    await launchUrl(uri);
  }

  /// Builds the text span for the message using irc colors.
  /// The text span is built using the [message] text.
  List<TextSpan> buildTextSpan(BuildContext context, ChannelMessage message) {
    var irc = IrcClient();
    final channel = irc.client.getChannel(message.channel);
    List<String?> nickList;
    if (channel == null) {
      nickList = [];
    } else {
      nickList = channel.allUsers.map((e) => e?.nickname).toList();
    }
    List<TextSpan> textSpans = [];

    Color? foregroundColor = IrcColors.defaultColor;
    Color? backgroundColor;
    bool isBold = false;
    bool isItalic = false;
    bool isUnderline = false;
    backgroundColor = null;

    ColorAndSize getColor(int i) {
      final c1 = message.text.characters.elementAt(i + 1);
      final c2 = message.text.characters.elementAt(i + 2);
      String character;
      if (int.tryParse(c2) != null) {
        character = c1 + c2;
      } else {
        character = "0$c1";
      }
      return ColorAndSize(IrcColors.getColor(character), character.length);
    }

    final urlIndexes = regUrl.allMatches(message.text).toList();
    var nextUrlIndex = 0;

    // Regex that could be any of the words in nickList
    String nickRegexStr = "";
    for (final nick in nickList) {
      if (nick == null) continue;
      nickRegexStr += "$nick|";
    }
    nickRegexStr = nickRegexStr.substring(0, nickRegexStr.length - 1);
    final regNick = RegExp("\\b(${nickRegexStr})\\b", caseSensitive: false);
    final nickIndexes = regNick.allMatches(message.text).toList();
    var nextNickIndex = 0;

    for (int i = 0; i < message.text.length; i++) {
      // ----------------------------------------------------------------
      // URL handling
      final nextUrlMatch =
          urlIndexes.isNotEmpty && urlIndexes.length > nextUrlIndex ? urlIndexes.elementAt(nextUrlIndex) : null;
      if (nextUrlMatch != null && i == nextUrlMatch.start) {
        final url = nextUrlMatch.group(0) ?? "";
        textSpans.add(
          TextSpan(
            text: url,
            style: TextStyle(
              color: Colors.blue,
              backgroundColor: backgroundColor,
              fontWeight: (isBold ? FontWeight.bold : FontWeight.normal),
              fontStyle: (isItalic ? FontStyle.italic : FontStyle.normal),
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _launchUrl(context, url);
              },
          ),
        );
        i = nextUrlMatch.end;
        nextUrlIndex++;
        continue;
      }
      // ----------------------------------------------------------------
      // Nick handling
      var nextNickMatch =
          nickIndexes.isNotEmpty && nickIndexes.length > nextNickIndex ? nickIndexes.elementAt(nextNickIndex) : null;
      if (nextNickMatch != null && i == nextNickMatch.start) {
        final nick = nextNickMatch.group(0) ?? "";
        textSpans.add(TextSpan(
          text: nick,
          style: TextStyle(
            color: nickColor(nick),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ));
        i = nextNickMatch.end - 1;
        nextNickIndex++;
        continue;
      }

      // ----------------------------------------------------------------
      // Text formatting handling
      String character = message.text.characters.elementAt(i);
      if (character == IrcColors.escape) {
        // Check for background color
        character = message.text.characters.elementAt(i + 1);
        if (character == ",") {
          var c = getColor(i + 1);
          foregroundColor = IrcColors.defaultColor;
          backgroundColor = c.color;
          if (backgroundColor == null) {
            backgroundColor = null;
            continue;
          }
          i += character.length + 2;
          continue;
        }
        // Check for foreground color
        var c = getColor(i);
        foregroundColor = c.color;
        if (foregroundColor == null) {
          backgroundColor = null;
          continue;
        }
        var addBy = c.size;

        // Background color
        character = message.text.characters.elementAt(i + 3);
        if (character == ",") {
          var c = getColor(i + 3);
          backgroundColor = c.color;
          addBy += c.size + 1;
        }
        i += addBy;
        continue;
      }

      switch (character) {
        case boldEscape:
          isBold = !isBold;
          break;

        case italicEscape:
          isItalic = !isItalic;
          break;

        case underlineEscape:
          isUnderline = !isUnderline;
          break;

        default:
          // Add the text span.
          textSpans.add(TextSpan(
            text: character,
            style: TextStyle(
              color: foregroundColor,
              backgroundColor: backgroundColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              decoration:
                  isUnderline ? TextDecoration.underline : TextDecoration.none,
              fontSize: 15,
            ),
          ));
      }
    }
    return textSpans;
  }
  // ----------------------------------------------------------------
}
