import 'package:flutter/material.dart';

final List<Color> userColorPallete = <Color>[
  Colors.blue[200]!,
  Colors.red[200]!,
  Colors.green[200]!,
  Colors.orange[200]!,
  Colors.cyan[200]!,
  Colors.lightBlue[200]!,
  Colors.lightGreen[200]!,
  Colors.purple[200]!,
  Colors.indigo[200]!,
  Colors.teal[200]!,
  Colors.red[200]!,
];

Color nickColor(String nick) {
  return userColorPallete[nick.hashCode % userColorPallete.length];
}

void showToast(BuildContext context, String message, [int time = 3]) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: Duration(seconds: time),
  ));
}

/// Returns "Now" if in the last 10 minutes, otherwise the hour if on the same day
/// otherwise the day and the month if in the same year, otherwise day month year
String datetimeToString(DateTime? dateTime) {
  if (dateTime == null) {
    return "";
  }
  final now = DateTime.now();
  // Format to 2 digits
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');

  if (now.difference(dateTime).inMinutes < 1) {
    return "Now";
  } else
  if (dateTime.day == now.day) {
    return "$hour:$minute";
  } else if (dateTime.year == now.year) {
    return "$day/$month $hour:$minute";
  } else {
    return "$day/$month/${dateTime.year} $hour:$minute";
  }
}
