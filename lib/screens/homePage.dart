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
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.group_work),
                  label: Text("Channels"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.message),
                  label: Text("Chats"),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.group_work),
              label: "Channels",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: "Chats",
            ),
          ],
        ),
      ),
    );
  }
}
