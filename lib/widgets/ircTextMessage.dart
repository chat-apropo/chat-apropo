import 'package:flutter/material.dart';

import '../models/channelMessageModel.dart';
import '../utils.dart';

RegExp regIgnoreChars = RegExp(r""",|\.|;|'|@|"|\*|\?|""");

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

class IrcText extends StatelessWidget {
  final ChannelMessage message;
  const IrcText({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String nickname =
        message.sender.toLowerCase().replaceAll(regIgnoreChars, "");
    var color = nickColor(nickname);
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
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
          padding: const EdgeInsets.all(16),
          child: SelectableText.rich(
            TextSpan(
              text: "${message.sender}\n",
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
              children: buildTextSpan(message),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the text span for the message using irc colors.
  /// The text span is built using the [message] text.
  List<TextSpan> buildTextSpan(ChannelMessage message) {
    // Loop over the message text and build the text span.
    List<TextSpan> textSpans = [];

    Color? foregroundColor = IrcColors.defaultColor;
    Color? backgroundColor;
    bool isBold = false;
    bool isItalic = false;
    bool isUnderline = false;
    backgroundColor = null;

    ColorAndSize getColor(int i) {
      var character = message.text.characters.elementAt(i + 1) +
          message.text.characters.elementAt(i + 2);
      return ColorAndSize(IrcColors.getColor(character), character.length);
    }

    for (int i = 0; i < message.text.length; i++) {
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
}
