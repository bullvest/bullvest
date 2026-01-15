import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';
import 'chat_screen.dart';

class StartupDetailScreen extends StatelessWidget {
  final String startupId;

  const StartupDetailScreen({Key? key, required this.startupId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final portfolioRef =
        FirebaseFirestore.instance.collection('portfolio').doc(startupId);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Startup Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: portfolioRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? 'Unnamed',
                    style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Industry: ${data['industry'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text('Stage: ${data['stage'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text('Funding Needed: \$${data['funding'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Text('Description:',
                    style: const TextStyle(
                        color: Colors.tealAccent, fontSize: 18)),
                const SizedBox(height: 4),
                Text(data['description'] ?? '',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                if (data['pitchDeckUrl'] != null && data['pitchDeckUrl'] != '')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('View Pitch Deck'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black),
                    onPressed: () {
                      // Open PDF (or use webview/pdf viewer package)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PitchDeckViewer(url: data['pitchDeckUrl']),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Open chat
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          startupId: startupId,
                          founderId: data['uid'],
                          dealInvestorId: AppConstants.currentUser.id ?? '',
                        ),
                      ),
                    );
                  },
                  child: const Text('Connect & Chat'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PitchDeckViewer extends StatelessWidget {
  final String url;
  const PitchDeckViewer({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Pitch Deck'), backgroundColor: Colors.black),
      body: Center(
        child: Text('Render PDF from URL: $url',
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
