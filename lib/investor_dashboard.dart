import 'package:flutter/material.dart';
import 'package:bullvest/investor_interest_form.dart';

class InvestorDashboard extends StatelessWidget {
  final VoidCallback onLogout;

  InvestorDashboard({required this.onLogout});

  final List<Map<String, String>> investments = [
    {'startup': 'HealthTech App', 'stage': 'Seed\nAction: close  remove'},
    {'startup': 'Green Energy Co', 'stage': 'Series A\nAction: close  remove'},
    {'startup': 'FintechX', 'stage': 'Pre-Seed\nAction: close  remove'},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Investor Dashboard'),
        backgroundColor: Colors.black,
        elevation: 0,
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
                itemCount: investments.length,
                itemBuilder: (context, index) {
                  final item = investments[index];
                  return Card(
                    color: Colors.grey[900],
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(item['startup'] ?? '',
                          style: TextStyle(color: Colors.tealAccent)),
                      subtitle: Text('Stage: ${item['stage']}',
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
                    MaterialPageRoute(builder: (_) => InvestorInterestForm()));
              },
              child: Text('Set Investment Preferences'),
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
