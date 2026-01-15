import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';
import 'chat_screen.dart';

class StartupDetailScreen extends StatefulWidget {
  final String startupId;

  const StartupDetailScreen({Key? key, required this.startupId})
      : super(key: key);

  @override
  State<StartupDetailScreen> createState() => _StartupDetailScreenState();
}

class _StartupDetailScreenState extends State<StartupDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _expandedDescription = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portfolioRef = FirebaseFirestore.instance
        .collection('portfolio')
        .doc(widget.startupId);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Startup Details'),
        elevation: 0,
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
          String? dealInvestorId = data['dealInvestorId'];
          final status = data['status'] ?? 'open';
          final canConnect = status == 'open' ||
              (status == 'deal_in_progress' &&
                  dealInvestorId == AppConstants.currentUser.id);

          // ===================== Carousel Info Cards =====================
          final infoCards = [
            {
              'label': 'Funding Needed',
              'value': '₦${data['funding'] ?? 'N/A'}'
            },
            {'label': 'Stage', 'value': data['stage'] ?? 'N/A'},
            {'label': 'Industry', 'value': data['industry'] ?? 'N/A'},
            {
              'label': 'Investors',
              'value': data['investorCount']?.toString() ?? '0'
            },
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===================== Header =====================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[900]!, Colors.grey[850]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.tealAccent,
                        offset: Offset(0, 2),
                        blurRadius: 6,
                        spreadRadius: 0.1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unnamed Startup',
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(data['industry'] ?? 'N/A'),
                            backgroundColor: Colors.tealAccent.withOpacity(0.2),
                            labelStyle:
                                const TextStyle(color: Colors.tealAccent),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(data['stage'] ?? 'N/A'),
                            backgroundColor: Colors.tealAccent.withOpacity(0.2),
                            labelStyle:
                                const TextStyle(color: Colors.tealAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ===================== Horizontal Info Cards =====================
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: infoCards.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final card = infoCards[index];
                      return Container(
                        width: 160,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.tealAccent, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              card['label']!,
                              style: const TextStyle(
                                color: Colors.tealAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              card['value']!,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ===================== Description =====================
                GestureDetector(
                  onTap: () {
                    setState(
                        () => _expandedDescription = !_expandedDescription);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                color: Colors.tealAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _expandedDescription
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.tealAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['description'] ?? 'No description provided.',
                          style: const TextStyle(color: Colors.white70),
                          maxLines: _expandedDescription ? null : 4,
                          overflow: _expandedDescription
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ===================== Pitch Deck =====================
                if (data['pitchDeckUrl'] != null &&
                    data['pitchDeckUrl'].toString().isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text(
                        'View Pitch Deck',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PitchDeckViewer(url: data['pitchDeckUrl']),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                // ===================== Connect Button =====================
                ScaleTransition(
                  scale: _pulseController,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canConnect
                          ? () async {
                              await FirebaseFirestore.instance
                                  .collection('portfolio')
                                  .doc(widget.startupId)
                                  .update({
                                'status': 'deal_in_progress',
                                'dealInvestorId': AppConstants.currentUser.id,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    startupId: widget.startupId,
                                    founderId: data['uid'],
                                    dealInvestorId:
                                        AppConstants.currentUser.id ?? '',
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        canConnect
                            ? 'Connect with Founder'
                            : status == 'deal_in_progress'
                                ? 'Deal In Progress'
                                : 'Connection Closed',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            canConnect ? Colors.tealAccent : Colors.grey,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
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
        title: const Text('Pitch Deck'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Text(
          'Render PDF from URL: $url',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
