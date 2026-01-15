import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/post_startup_form.dart';
import 'package:bullvest/model/app_constants.dart';
import 'subscribe_screen.dart';
import 'subscription_service.dart';

class FounderDashboard extends StatelessWidget {
  const FounderDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = AppConstants.currentUser.id;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subscriptionCard(context),
          const SizedBox(height: 16),
          const Text(
            'Your Portfolio',
            style: TextStyle(
              color: Colors.tealAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('portfolio')
                  .where('uid', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No portfolio items found.',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showStartupDetails(context, doc.id, data),
                      child: Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'Untitled',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['description'] ?? 'No description',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.payments,
                                      size: 16, color: Colors.tealAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${data['currency'] ?? '₦'}${formatCurrency(data['funding'] ?? 0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  _statusChip(data['status']),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Post Your Startup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get();

                final subscription = userDoc.data()?['subscription'];
                final active =
                    SubscriptionService.isSubscriptionActive(subscription);

                if (!active) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Active subscription required to post'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostStartupForm(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= SUBSCRIPTION CARD =================

  Widget _subscriptionCard(BuildContext context) {
    final userId = AppConstants.currentUser.id;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final subscription = data?['subscription'];

        final bool isActive =
            SubscriptionService.isSubscriptionActive(subscription);

        int daysRemaining = 0;
        if (subscription?['expiresAt'] != null) {
          final expiry = (subscription!['expiresAt'] as Timestamp).toDate();
          daysRemaining =
              expiry.difference(DateTime.now()).inDays.clamp(0, 999);
        }

        return Card(
          color: isActive ? Colors.green[900] : Colors.red[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.verified : Icons.lock,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive
                            ? 'Subscription Active'
                            : 'Subscription Required',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive
                            ? '$daysRemaining day(s) remaining'
                            : '₦10,000 / 30 days',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isActive ? Colors.white : Colors.tealAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SubscribeScreen()),
                    );
                  },
                  child: Text(isActive ? 'Manage' : 'Subscribe'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= DETAILS & LOCK =================

  void _showStartupDetails(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final bool locked = data['status'] != 'open';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['name'] ?? '',
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _detailRow('Industry', data['industry']),
              _detailRow('Stage', data['stage']),
              _detailRow(
                'Funding',
                '${data['currency'] ?? '₦'}${formatCurrency(data['funding'] ?? 0)}',
              ),
              _detailRow('Location', data['location']),
              const SizedBox(height: 12),
              const Text(
                'Description',
                style: TextStyle(
                    color: Colors.tealAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(data['description'] ?? '',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              if (locked)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'This startup is in an active deal.\n'
                    'Editing and deletion are locked.\n\n'
                    'Please contact admin.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= HELPERS =================

Widget _statusChip(String? status) {
  final locked = status == 'deal_in_progress';

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: locked ? Colors.orange[800] : Colors.green[800],
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status?.replaceAll('_', ' ').toUpperCase() ?? 'OPEN',
      style: const TextStyle(
          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _detailRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text('$label: ', style: TextStyle(color: Colors.grey[400])),
        Expanded(
          child:
              Text(value ?? 'N/A', style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

String formatCurrency(num amount) {
  return amount
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}
