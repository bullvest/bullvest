import 'package:flutter/material.dart';
import '../profile_screen.dart';
import 'package:bullvest/investor/marketplace_screen.dart';
import 'package:bullvest/allchat_screen.dart';

class InvestorBottomNav extends StatefulWidget {
  const InvestorBottomNav({Key? key}) : super(key: key);

  @override
  State<InvestorBottomNav> createState() => _InvestorBottomNavState();
}

class _InvestorBottomNavState extends State<InvestorBottomNav> {
  int _index = 0;

  final pages = const [
    MarketplaceScreen(),
    AllChatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
