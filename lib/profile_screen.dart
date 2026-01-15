import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bullvest/model/app_constants.dart';
import 'package:bullvest/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isFounder = false;
  bool _isUpdatingRole = false;

  Future<Map<String, dynamic>> _fetchUserDataWithStartups() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(AppConstants.currentUser.id)
        .get();

    if (!userDoc.exists) throw Exception("User not found");

    final userData = userDoc.data()!;
    final postingIDs = List<String>.from(userData['myPostingIDs'] ?? []);

    List<Map<String, dynamic>> startups = [];

    if (postingIDs.isNotEmpty) {
      final portfolioSnapshots = await Future.wait(
        postingIDs.map(
          (id) =>
              FirebaseFirestore.instance.collection('portfolio').doc(id).get(),
        ),
      );

      startups = portfolioSnapshots
          .where((doc) => doc.exists)
          .map((doc) => doc.data()!)
          .cast<Map<String, dynamic>>()
          .toList();
    }

    _isFounder = userData['type'] == 'founder';

    return {
      'userData': userData,
      'startups': startups,
    };
  }

  Future<void> _updateUserRole(bool isFounder) async {
    setState(() => _isUpdatingRole = true);
    final newRole = isFounder ? 'founder' : 'investor';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(AppConstants.currentUser.id)
        .update({'type': newRole});

    setState(() {
      _isFounder = isFounder;
      _isUpdatingRole = false;
    });
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Edit $field',
          style: const TextStyle(color: Colors.tealAccent),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter $field',
            hintStyle: TextStyle(color: Colors.grey[500]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(AppConstants.currentUser.id)
                  .update({field: controller.text.trim()});
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserDataWithStartups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text(
                'Failed to load profile data.',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final userData = snapshot.data!['userData'] as Map<String, dynamic>;
          final startups =
              snapshot.data!['startups'] as List<Map<String, dynamic>>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _profileHeader(userData),
                const SizedBox(height: 24),
                _roleSwitchCard(),
                const SizedBox(height: 24),
                _editableInfoCard(userData),
                const SizedBox(height: 24),
                _startupsSection(startups),
                const SizedBox(height: 32),
                _logoutButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===================== UI COMPONENTS =====================

  Widget _profileHeader(Map<String, dynamic> userData) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.tealAccent,
          child: Text(
            userData['firstName']?[0]?.toUpperCase() ?? '?',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${userData['firstName']} ${userData['lastName']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                userData['email'] ?? '',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roleSwitchCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Role',
              style: TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _isFounder
                  ? 'Founder: tap toggle to enter Investor mode'
                  : 'Investor: tap toggle to enter Founder mode',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _isUpdatingRole
                    ? const CircularProgressIndicator(color: Colors.tealAccent)
                    : Switch(
                        value: _isFounder,
                        activeColor: Colors.tealAccent,
                        onChanged: (value) => _updateUserRole(value),
                      ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _editableInfoCard(Map<String, dynamic> userData) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _editableRow('firstName', 'First Name', userData['firstName']),
            _editableRow('lastName', 'Last Name', userData['lastName']),
            _editableRow('mobileNumber', 'Mobile', userData['mobileNumber']),
            _editableRow('country', 'Country', userData['country']),
            _editableRow('state', 'State', userData['state']),
          ],
        ),
      ),
    );
  }

  Widget _editableRow(String field, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.tealAccent)),
      subtitle: Text(
        value ?? 'N/A',
        style: const TextStyle(color: Colors.white),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit, color: Colors.tealAccent),
        onPressed: () => _editField(field, value ?? ''),
      ),
    );
  }

  Widget _startupsSection(List<Map<String, dynamic>> startups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Startups',
          style: TextStyle(
            color: Colors.tealAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        startups.isEmpty
            ? Text(
                'No startups posted yet.',
                style: TextStyle(color: Colors.grey[400]),
              )
            : SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: startups.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final startup = startups[index];
                    return _startupCard(startup);
                  },
                ),
              ),
      ],
    );
  }

  Widget _startupCard(Map<String, dynamic> startup) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            startup['name'] ?? 'Untitled',
            style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              startup['description'] ?? 'No description.',
              style: const TextStyle(color: Colors.white70),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout),
        label: const Text('Log Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
