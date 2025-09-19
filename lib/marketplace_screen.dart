import 'package:flutter/material.dart';
import 'chat_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  final String userRole; // 'investor' or 'founder'

  MarketplaceScreen({required this.userRole});

  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final Set<int> matchedIndexes = {};

  final List<Map<String, String>> startups = [
    {
      'name': 'HealthTech AI',
      'industry': 'Healthcare',
      'stage': 'Seed',
      'fundingNeeded': '\$100k',
      'description': 'AI-powered diagnostics platform.'
    },
    {
      'name': 'FinTrack',
      'industry': 'Fintech',
      'stage': 'Series A',
      'fundingNeeded': '\$2M',
      'description': 'Personal finance management app.'
    },
  ];

  final List<Map<String, String>> investors = [
    {
      'name': 'Jane Doe',
      'sectorFocus': 'Healthcare, Fintech',
      'ticketSize': '\$50k - \$500k',
      'location': 'Nigeria',
      'interests': 'Early-stage startups'
    },
    {
      'name': 'John Smith',
      'sectorFocus': 'SaaS, AI',
      'ticketSize': '\$100k - \$1M',
      'location': 'Kenya',
      'interests': 'Growth-stage ventures'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isInvestor = widget.userRole == 'investor';

    return Scaffold(
      appBar: AppBar(
        title:
            Text(isInvestor ? 'Startup Opportunities' : 'Potential Investors'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: isInvestor ? startups.length : investors.length,
        itemBuilder: (context, index) {
          if (isInvestor) {
            final startup = startups[index];
            final isMatched = matchedIndexes.contains(index);

            return Card(
              color: Colors.grey[900],
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(startup['name']!,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.tealAccent)),
                    SizedBox(height: 6),
                    Text('Industry: ${startup['industry']}',
                        style: TextStyle(color: Colors.white70)),
                    Text('Stage: ${startup['stage']}',
                        style: TextStyle(color: Colors.white70)),
                    Text('Funding Needed: ${startup['fundingNeeded']}',
                        style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Text(startup['description']!,
                        style: TextStyle(color: Colors.white)),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isMatched
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChatScreen(name: startup['name']!),
                                ),
                              );
                            }
                          : () {
                              setState(() {
                                matchedIndexes.add(index);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'You matched with ${startup['name']}')),
                              );
                            },
                      child: Text(isMatched ? 'Message' : 'Match'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isMatched ? Colors.teal : Colors.tealAccent,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            final investor = investors[index];

            return Card(
              color: Colors.grey[900],
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(investor['name']!,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.tealAccent)),
                    SizedBox(height: 6),
                    Text('Sector Focus: ${investor['sectorFocus']}',
                        style: TextStyle(color: Colors.white70)),
                    Text('Ticket Size: ${investor['ticketSize']}',
                        style: TextStyle(color: Colors.white70)),
                    Text('Location: ${investor['location']}',
                        style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Text('Interests: ${investor['interests']}',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
