import 'package:flutter/material.dart';
import 'package:gasconchat/screens/chatPage.dart';

import '../ircClient.dart';
import 'chanPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIndex = 0;
  var pages = [
    const ChanPage(),
    const ChatPage(),
  ];

 @override
 void initState() {
   super.initState();
   var client = IrcClient();
   client.connect();
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[pageIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        currentIndex: pageIndex,
        onTap: (index) {
          setState(() {
            pageIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group_work),
            label: "Channels",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: "Chats",
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.account_box),
          //   label: "Profile",
          // ),
        ],
      ),
    );
  }
}
