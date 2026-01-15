import 'package:flutter/material.dart';
import '../profile_screen.dart';
import 'founder_dashboard.dart';

class FounderBottomNav extends StatefulWidget {
  const FounderBottomNav({Key? key}) : super(key: key);

  @override
  State<FounderBottomNav> createState() => _FounderBottomNavState();
}

class _FounderBottomNavState extends State<FounderBottomNav> {
  int _index = 0;

  final pages = const [
    FounderDashboard(),
    ProfileScreen(),
  ];

  final titles = const [
    'Founder Dashboard',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(titles[_index]),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        currentIndex: _index,
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center),
            label: 'Startups',
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
