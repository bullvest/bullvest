import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'User Profile Info Here',
          style: TextStyle(color: Colors.tealAccent, fontSize: 22),
        ),
      ),
    );
  }
}
