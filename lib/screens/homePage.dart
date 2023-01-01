import 'package:audioplayers/audioplayers.dart';
import 'package:chat_apropo/i18n.dart';
import 'package:chat_apropo/models/dbhelpers.dart';
import 'package:flutter/material.dart';
import 'package:chat_apropo/screens/chatPage.dart';

import '../ircClient.dart';
import 'chanPage.dart';

class HomePage extends StatefulWidget {
  final Account account;
  const HomePage({Key? key, required this.account}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIndex = 0;
  bool bottomNavbarVisible = true;

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
    bottomNavbarVisible = MediaQuery.of(context).size.height >
        MediaQuery.of(context).size.width;

    return Scaffold(
      body: Row(
        children: [
          Visibility(
            visible: !bottomNavbarVisible,
            child: NavigationRail(
              selectedIndex: pageIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  pageIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: const Icon(Icons.group_work),
                  label: Text("Channels".i18n),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.message),
                  label: Text("Chats".i18n),
                ),
              ],
            ),
          ),
          Expanded(child: pages[pageIndex]),
        ],
      ),
      bottomNavigationBar: Visibility(
        visible: bottomNavbarVisible,
        child: BottomNavigationBar(
          selectedItemColor: Colors.blue,
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
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.group_work),
              label: "Channels".i18n,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.message),
              label: "Chats".i18n,
            ),
          ],
        ),
      ),
    );
  }
}
