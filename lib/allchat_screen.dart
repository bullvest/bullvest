import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';
import 'investor/chat_screen.dart';

class AllChatsScreen extends StatelessWidget {
  const AllChatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = AppConstants.currentUser.id;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Chats', style: TextStyle(color: Colors.tealAccent)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No chats available',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // Filter chats where current user is either founder or dealInvestor
          final chats = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final founderId = data['founderId'] ?? '';
            final dealInvestorId = data['dealInvestorId'] ?? '';
            return currentUserId == founderId ||
                currentUserId == dealInvestorId;
          }).toList();

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                'No chats available for your account',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;

              final founderId = chatData['founderId'] ?? '';
              final dealInvestorId = chatData['dealInvestorId'] ?? '';
              final startupId = chatData['startupId'] ?? '';

              // Determine the "other user" to display
              final otherUserId =
                  currentUserId == founderId ? dealInvestorId : founderId;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const SizedBox();
                  }

                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>?;

                  final otherName =
                      '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}';

                  return Card(
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.tealAccent,
                        child: Text(
                          otherName.isNotEmpty
                              ? otherName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                      title: Text(
                        otherName,
                        style: const TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Tap to open chat',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              startupId: startupId,
                              founderId: founderId,
                              dealInvestorId: dealInvestorId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
