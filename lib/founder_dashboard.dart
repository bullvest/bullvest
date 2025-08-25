import 'package:flutter/material.dart';
import 'package:bullvest/post_startup_form.dart';

class FounderDashboard extends StatelessWidget {
  final VoidCallback onLogout;

  FounderDashboard({required this.onLogout});
  final List<Map<String, String>> portfolio = [
    {
      'name': 'HealthTech App',
      'description': 'A healthcare booking platform\n Status: pending'
    },
    {
      'name': 'GreenMart',
      'description':
          'An e-commerce platform for organic food\n Status: currently undergoing negotiation'
    },
    {
      'name': 'AI Chatbot',
      'description':
          'Customer support automation\n Status: matched - deal closed'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Founder Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Portfolio',
                style: TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: portfolio.length,
                itemBuilder: (context, index) {
                  final item = portfolio[index];
                  return Card(
                    color: Colors.grey[900],
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(item['name']!,
                          style: TextStyle(color: Colors.tealAccent)),
                      subtitle: Text(item['description']!,
                          style: TextStyle(color: Colors.grey[400])),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 6),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => PostStartupForm()));
              },
              child: Text('Post Your Startup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent, // Teal background
                foregroundColor: Colors.black, // Black text
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
