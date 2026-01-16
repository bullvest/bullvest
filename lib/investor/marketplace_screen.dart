import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';
import 'chat_screen.dart';
import 'startup_detail.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  String formatCurrency(num amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(),
            ),
            Expanded(
              child:
                  _buildStartupList(), // Expanded fixes scrolling & alignment
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search startups by name, industry, or description',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
        suffixIcon: searchQuery.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  searchController.clear();
                  setState(() => searchQuery = '');
                },
                child: const Icon(Icons.clear, color: Colors.redAccent),
              )
            : null,
        filled: true,
        fillColor: Colors.grey[900],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        setState(() => searchQuery = value);
      },
    );
  }

  Widget _buildStartupList() {
    return StreamBuilder<QuerySnapshot>(
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
            child: Text('No startups available',
                style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final startupId = doc.id;
            final founderId = data['uid'];
            final name = data['name'];
            final industry = data['industry'];
            final funding = data['funding'];
            final currency = data['currency'];
            final description = data['description'];
            final status = data['status'] ?? 'open';
            final dealInvestorId = data['dealInvestorId'];

            final canConnect = status == 'open' ||
                (status == 'deal_in_progress' &&
                    dealInvestorId == AppConstants.currentUser.id);

            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.tealAccent,
                          ),
                        ),
                        Chip(
                          backgroundColor: _statusColor(status),
                          label: Text(
                            _statusText(status),
                            style: const TextStyle(color: Colors.black),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Industry: $industry',
                        style: const TextStyle(color: Colors.white70)),
                    Text('Funding: $currency${formatCurrency(funding ?? 0)}',
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(description,
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StartupDetailScreen(startupId: startupId),
                            ),
                          );
                        },
                        child: Text('connect'),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'deal_in_progress':
        return Colors.orangeAccent;
      case 'deal_closed':
        return Colors.greenAccent;
      default:
        return Colors.tealAccent;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'deal_in_progress':
        return 'Deal in Progress';
      case 'deal_closed':
        return 'Deal Closed';
      default:
        return 'Connect';
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Search', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search startups',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
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
          ),
        ],
      ),
    );
  }
}
