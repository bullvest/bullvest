import 'package:flutter/material.dart';
import 'investors_dashboard.dart';
import 'marketplace_screen.dart';
import 'package:bullvest/profile_screen.dart';

class InvestorHomeScreen extends StatefulWidget {
  final String userRole; // 'investor' or 'founder'

  InvestorHomeScreen({required this.userRole});

  @override
  _InvestorHomeScreenState createState() => _InvestorHomeScreenState();
}

class _InvestorHomeScreenState extends State<InvestorHomeScreen> {
  int _selectedIndex = 0;

  void _logout() {
    Navigator.pushReplacementNamed(context, '/login'); // Or '/splash'
  }

  // Pages for bottom nav
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    if (widget.userRole == 'investor') {
      _pages = [
        InvestorsDashboard(userRole: 'investor'),
        MarketplaceScreen(userRole: 'investor'),
        ProfileScreen(), // optional profile/settings
      ];
    } else {
      _pages = [
        //  FounderDashboard(onLogout: _logout),
        // MarketplaceScreen(userRole: 'founder'),
        // ProfileScreen(),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Marketplace',
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
