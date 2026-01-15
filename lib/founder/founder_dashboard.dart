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
          /// ================= SUBSCRIPTION CARD =================
          _subscriptionCard(context),

          const SizedBox(height: 16),

          /// ================= TITLE =================
          const Text(
            'Your Portfolio',
            style: TextStyle(
              color: Colors.tealAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          /// ================= PORTFOLIO LIST =================
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

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          data['name'] ?? 'No name',
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              data['description'] ?? 'No description',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Funding: ${data['funding'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              'Status: ${data['status'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          color: Colors.grey[800],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditDialog(context, doc.id, data);
                            } else if (value == 'delete') {
                              _confirmDelete(context, doc.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ================= POST BUTTON =================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
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
              icon: const Icon(Icons.add),
              label: const Text('Post Your Startup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
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
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final subscription = data?['subscription'];

        final bool isActive =
            SubscriptionService.isSubscriptionActive(subscription);

        int daysRemaining = 0;

        if (subscription != null && subscription['expiresAt'] != null) {
          final expiry = (subscription['expiresAt'] as Timestamp).toDate();
          daysRemaining = expiry.difference(DateTime.now()).inDays;
          if (daysRemaining < 0) daysRemaining = 0;
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
                  size: 28,
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscribeScreen(),
                      ),
                    );
                    // Auto-refresh happens automatically
                    // because this card uses StreamBuilder
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isActive ? Colors.white : Colors.tealAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(isActive ? 'Manage' : 'Subscribe'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= EDIT =================

  void _showEditDialog(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name']);
    final descriptionController =
        TextEditingController(text: data['description']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text('Edit Startup', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Name', nameController),
            _field('Description', descriptionController, maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('portfolio')
                  .doc(docId)
                  .update({
                'name': nameController.text,
                'description': descriptionController.text,
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent),
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelStyle: TextStyle(color: Colors.tealAccent),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.tealAccent),
          ),
        ),
      ),
    );
  }

  // ================= DELETE =================

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text('Delete Startup', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this startup?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('portfolio')
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
