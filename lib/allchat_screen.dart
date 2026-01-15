import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';
import 'investor/chat_screen.dart';

class AllChatsScreen extends StatefulWidget {
  const AllChatsScreen({Key? key}) : super(key: key);

  @override
  State<AllChatsScreen> createState() => _AllChatsScreenState();
}

class _AllChatsScreenState extends State<AllChatsScreen> {
  final currentUserId = AppConstants.currentUser.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: currentUserId)
              .snapshots(),
          builder: (context, chatSnapshot) {
            if (chatSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent));
            }

            if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No chats yet',
                      style: TextStyle(color: Colors.grey)));
            }

            final chats = chatSnapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chatDoc = chats[index];
                final chatData = chatDoc.data() as Map<String, dynamic>?;

                if (chatData == null) return const SizedBox();

                final participants =
                    List<String>.from(chatData['participants'] ?? []);
                final otherUserId =
                    participants.firstWhere((id) => id != currentUserId);
                final startupId = chatData['startupId'] ?? '';
                final dealStatus = chatData['dealStatus'] ?? 'open';
                final unreadCount =
                    (chatData['unread']?[currentUserId] ?? 0) as int;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .get(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) return const SizedBox();

                    final userData =
                        userSnap.data!.data() as Map<String, dynamic>?;
                    final otherName =
                        '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}';

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chatDoc.id)
                          .collection('messages')
                          .orderBy('createdAt', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, messageSnap) {
                        String lastMessage = 'No messages yet';

                        if (messageSnap.hasData &&
                            messageSnap.data!.docs.isNotEmpty) {
                          final latestMessage = messageSnap.data!.docs.first
                              .data() as Map<String, dynamic>;
                          lastMessage = latestMessage['text'] ?? '';
                        }

                        return Card(
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 12),
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
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    startupId: startupId,
                                    founderId: chatData['founderId'] ?? '',
                                    dealInvestorId:
                                        chatData['dealInvestorId'] ?? '',
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
            );
          },
        ),
      ),
    );
  }
}
