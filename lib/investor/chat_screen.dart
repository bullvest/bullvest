import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';

class ChatScreen extends StatefulWidget {
  final String startupId; // Startup being discussed
  final String founderId;
  final String dealInvestorId;

  const ChatScreen({
    Key? key,
    required this.startupId,
    required this.founderId,
    required this.dealInvestorId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late final String chatId;
  late Future<bool> _canAccessChat;

  @override
  void initState() {
    super.initState();
    chatId = '${widget.startupId}_${widget.founderId}_${widget.dealInvestorId}';
    _canAccessChat = _validateChatAccess();
    _resetUnread();
  }

  Future<bool> _validateChatAccess() async {
    final doc = await FirebaseFirestore.instance
        .collection('portfolio')
        .doc(widget.startupId)
        .get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final status = data['status'];

    final currentUserId = AppConstants.currentUser.id;

    // Only founder or investor on this deal can chat
    if (currentUserId != widget.founderId &&
        currentUserId != widget.dealInvestorId) return false;

    // Only allow chatting if deal is in progress or closed
    return status != 'open';
  }

  Future<void> _resetUnread() async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    await chatRef.set({
      'unread.${AppConstants.currentUser.id}': 0,
      'participants': [widget.founderId, widget.dealInvestorId]
    }, SetOptions(merge: true));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'text': text,
      'senderId': AppConstants.currentUser.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment unread for other participant
    final otherUser = AppConstants.currentUser.id == widget.founderId
        ? widget.dealInvestorId
        : widget.founderId;

    await chatRef.set({
      'unread.$otherUser': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canAccessChat,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            ),
          );
        }

        if (!snapshot.data!) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'You no longer have access to this conversation.',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Chat'),
          ),
          body: Column(
            children: [
              Expanded(child: _buildMessages()),
              _buildInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessages() {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: messagesRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.tealAccent),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isMe = data['senderId'] == AppConstants.currentUser.id;

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isMe ? Colors.tealAccent : Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['text'] ?? '',
                  style: TextStyle(color: isMe ? Colors.black : Colors.white),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.tealAccent,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.black),
              onPressed: _sendMessage,
            ),
          )
        ],
      ),
    );
  }
}
