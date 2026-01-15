import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';
import 'investor/chat_screen.dart'; // adjust the path

class AllChatsScreen extends StatelessWidget {
  const AllChatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = AppConstants.currentUser.id;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastUpdated', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No chats yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final chatData = chat.data() as Map<String, dynamic>;

              final participants =
                  List<String>.from(chatData['participants'] ?? []);
              final otherUserId =
                  participants.firstWhere((id) => id != currentUserId);

              final startupId = chatData['startupId'] ?? '';
              final lastMessage = chatData['lastMessage'] ?? '';
              final unreadCount =
                  (chatData['unread']?[currentUserId] ?? 0) as int;
              final dealStatus = chatData['dealStatus'] ?? 'open';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  final userData =
                      userSnapshot.data?.data() as Map<String, dynamic>?;

                  final otherName =
                      '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}';

                  return ListTile(
                    tileColor: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.tealAccent,
                      child: Text(
                        otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    title: Text(
                      otherName,
                      style: const TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          dealStatus.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.tealAccent, fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navigate to individual chat

                      // Determine founder and investor from participants
                      final currentUserId = AppConstants.currentUser.id;
                      final founderId = chatData['founderId'] ?? '';
                      final dealInvestorId = chatData['dealInvestorId'] ?? '';

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
