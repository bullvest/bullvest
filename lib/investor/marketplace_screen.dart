import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  final String userRole;

  MarketplaceScreen({required this.userRole});

  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final Set<String> matchedDocIds = {};
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool showStartups = true; // Toggle flag

  Map<String, String> userCache = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          showStartups ? 'Startup Opportunities' : 'Investor Profiles',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.tealAccent),
            onPressed: () => _showSearchDialog(context),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                showStartups = !showStartups;
              });
            },
            child: Text(
              showStartups ? 'Show Investors' : 'Show Startups',
              style: TextStyle(color: Colors.tealAccent),
            ),
          ),
        ],
      ),
      body: showStartups ? _buildStartupList() : _buildInvestorList(),
    );
  }

  // 🔁 STARTUP LIST
  Widget _buildStartupList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('portfolio')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildError('Error loading startups.');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        final docs = snapshot.data?.docs ?? [];

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final industry = (data['industry'] ?? '').toString().toLowerCase();
          final funding = (data['funding'] ?? '').toString().toLowerCase();
          final status = (data['status'] ?? '').toString().toLowerCase();
          final query = searchQuery.toLowerCase();

          return name.contains(query) ||
              industry.contains(query) ||
              funding.contains(query) ||
              status.contains(query);
        }).toList();

        if (filteredDocs.isEmpty) return _buildMessage('No startups found.');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;

            final name = data['name'] ?? 'Unnamed';
            final industry = data['industry'] ?? 'N/A';
            final stage = data['stage'] ?? 'N/A';
            final funding = data['funding'] ?? 'N/A';
            final description = data['description'] ?? '';
            final status = data['status'] ?? 'unknown';
            final uid = data['uid'] ?? '';
            final isMatched = matchedDocIds.contains(docId);

            return FutureBuilder<String>(
              future: _getUserFullName(uid),
              builder: (context, snapshot) {
                final fullName = snapshot.data ?? 'Unknown Founder';

                return Card(
                  color: Colors.grey[900],
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.tealAccent)),
                        SizedBox(height: 6),
                        Text('Posted by: $fullName',
                            style: TextStyle(color: Colors.white70)),
                        Text('Industry: $industry',
                            style: TextStyle(color: Colors.white70)),
                        Text('Stage: $stage',
                            style: TextStyle(color: Colors.white70)),
                        Text('Funding Needed: \$${funding}',
                            style: TextStyle(color: Colors.white70)),
                        Text('Status: $status',
                            style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 8),
                        Text(description,
                            style: TextStyle(color: Colors.white)),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            // Connect via chat
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(name: fullName),
                              ),
                            );
                          },
                          child: Text('Connect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // 🔁 INVESTOR LIST
  Widget _buildInvestorList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('type', isEqualTo: 'investor')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildError('Error loading investors.');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        final docs = snapshot.data?.docs ?? [];

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = '${data['firstname'] ?? ''} ${data['lastname'] ?? ''}'
              .toLowerCase();
          final location = (data['location'] ?? '').toString().toLowerCase();
          final interests = (data['interests'] ?? '').toString().toLowerCase();
          final query = searchQuery.toLowerCase();

          return name.contains(query) ||
              location.contains(query) ||
              interests.contains(query);
        }).toList();

        if (filteredDocs.isEmpty) return _buildMessage('No investors found.');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data() as Map<String, dynamic>;

            final name = '${data['firstname'] ?? ''} ${data['lastname'] ?? ''}';
            final sectorFocus = data['sectorFocus'] ?? 'N/A';
            final ticketSize = data['ticketSize'] ?? 'N/A';
            final location = data['location'] ?? 'N/A';
            final interests = data['interests'] ?? '';

            return Card(
              color: Colors.grey[900],
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.tealAccent)),
                    SizedBox(height: 6),
                    Text('Sector Focus: $sectorFocus',
                        style: TextStyle(color: Colors.white70)),
                    Text('Ticket Size: $ticketSize',
                        style: TextStyle(color: Colors.white70)),
                    Text('Location: $location',
                        style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Text('Interests: $interests',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🔁 Get full name using UID from users collection
  Future<String> _getUserFullName(String uid) async {
    if (userCache.containsKey(uid)) {
      return userCache[uid]!;
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        final first = data['firstname'] ?? '';
        final last = data['lastname'] ?? '';
        final fullName = '$first $last'.trim();
        userCache[uid] = fullName;
        return fullName;
      }
    } catch (_) {}

    return 'Unknown User';
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Search', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: searchController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: showStartups
                ? 'Search startups (name, industry, funding, status)'
                : 'Search investors (name, location, interests)',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              searchController.clear();
              setState(() => searchQuery = '');
              Navigator.pop(context);
            },
            child: Text('Clear', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                searchQuery = searchController.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent),
            child: Text('Search', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) =>
      Center(child: Text(message, style: TextStyle(color: Colors.redAccent)));

  Widget _buildMessage(String message) =>
      Center(child: Text(message, style: TextStyle(color: Colors.grey)));

  Widget _buildLoading() =>
      Center(child: CircularProgressIndicator(color: Colors.tealAccent));
}
