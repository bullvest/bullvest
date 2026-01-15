import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';
import 'investor/chat_screen.dart'; // adjust the path

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, chatSnapshot) {
          if (!chatSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          final chats = chatSnapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(
              child: Text('No chats yet', style: TextStyle(color: Colors.grey)),
            );
          }

          // For each chat, get its latest message timestamp
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getChatsWithLatestMessages(chats),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                );
              }

              final chatsWithLatest = snapshot.data!;

              // Sort chats by latest message timestamp descending
              chatsWithLatest.sort((a, b) {
                final tsA = a['latestMessageTime'] as Timestamp?;
                final tsB = b['latestMessageTime'] as Timestamp?;
                return (tsB ?? Timestamp(0, 0))
                    .compareTo(tsA ?? Timestamp(0, 0));
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chatsWithLatest.length,
                itemBuilder: (context, index) {
                  final chatInfo = chatsWithLatest[index];
                  final chatData = chatInfo['chatData'] as Map<String, dynamic>;
                  final chatDocId = chatInfo['chatDocId'] as String;
                  final lastMessage = chatInfo['lastMessage'] as String;
                  final otherUserId = chatInfo['otherUserId'] as String;
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

                      return Card(
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                            lastMessage.isEmpty
                                ? 'No messages yet'
                                : lastMessage,
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
    );
  }

  Future<List<Map<String, dynamic>>> _getChatsWithLatestMessages(
      List<QueryDocumentSnapshot> chats) async {
    final List<Map<String, dynamic>> result = [];

    for (var chatDoc in chats) {
      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(chatData['participants'] ?? []);
      final otherUserId = participants.firstWhere((id) => id != currentUserId);

      // Get latest message
      final messagesQuery = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatDoc.id)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      String lastMessage = '';
      Timestamp? latestMessageTime;
      if (messagesQuery.docs.isNotEmpty) {
        final msgData = messagesQuery.docs.first.data();
        lastMessage = msgData['text'] ?? '';
        latestMessageTime = msgData['createdAt'] as Timestamp?;
      }

      result.add({
        'chatDocId': chatDoc.id,
        'chatData': chatData,
        'otherUserId': otherUserId,
        'lastMessage': lastMessage,
        'latestMessageTime': latestMessageTime,
      });
    }

    return result;
  }
}
