import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'startup_detail.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.tealAccent),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('portfolio')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text('No startups found.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final startupId = docs[index].id;

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    data['name'] ?? 'Unnamed',
                    style: const TextStyle(
                        color: Colors.tealAccent, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    data['industry'] ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Icon(Icons.arrow_forward, color: Colors.tealAccent),
                  onTap: () => _openStartupDetails(startupId),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openStartupDetails(String startupId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartupDetailScreen(startupId: startupId),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Search Startups',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search by name or industry',
            hintStyle: TextStyle(color: Colors.grey[500]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              searchController.clear();
              setState(() => searchQuery = '');
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => searchQuery = searchController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent),
            child: const Text('Search', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }
}
