import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';

class ChatScreen extends StatefulWidget {
  final String startupId;
  final String founderId;
  final String startupName;

  const ChatScreen({
    Key? key,
    required this.startupId,
    required this.founderId,
    required this.startupName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  String get chatId => widget.startupId; // one chat per startup

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.startupName),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleDealAction,
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'close', child: Text('Mark Deal Closed')),
              const PopupMenuItem(value: 'cancel', child: Text('Cancel Deal')),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isMe = data['senderId'] == AppConstants.currentUser.id;

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isMe ? Colors.tealAccent : Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['text'],
                  style: TextStyle(color: isMe ? Colors.black : Colors.white),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[900],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Type message...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.tealAccent),
            onPressed: _sendMessage,
          )
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': AppConstants.currentUser.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleDealAction(String action) async {
    final ref = FirebaseFirestore.instance
        .collection('portfolio')
        .doc(widget.startupId);

    if (action == 'close') {
      await ref.update({'status': 'deal_closed'});
    } else if (action == 'cancel') {
      await ref.update({
        'status': 'open',
        'dealInvestorId': null,
      });
    }

    Navigator.pop(context);
  }
}
