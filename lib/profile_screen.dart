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

    if (!userDoc.exists) {
      throw Exception("User not found");
    }

    final userData = userDoc.data()!;
    final postingIDs = List<String>.from(userData['myPostingIDs'] ?? []);

    List<String> startupNames = [];

    if (postingIDs.isNotEmpty) {
      final portfolioSnapshots = await Future.wait(
        postingIDs.map(
          (id) =>
              FirebaseFirestore.instance.collection('portfolio').doc(id).get(),
        ),
      );

      startupNames = portfolioSnapshots
          .where((doc) => doc.exists)
          .map((doc) => doc.data()?['name'] ?? 'Untitled')
          .cast<String>()
          .toList();
    }

    _isFounder = userData['type'] == 'founder';

    return {
      'userData': userData,
      'startupNames': startupNames,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
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
          final startupNames = snapshot.data!['startupNames'] as List<String>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _profileHeader(userData),
                const SizedBox(height: 24),
                _roleSwitchCard(),
                const SizedBox(height: 24),
                _infoCard(userData, startupNames),
                const SizedBox(height: 24),
                _startupsCard(startupNames),
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
          radius: 32,
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
        Column(
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
      ],
    );
  }

  Widget _roleSwitchCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Role',
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isFounder ? 'Founder Mode' : 'Investor Mode',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            _isUpdatingRole
                ? const CircularProgressIndicator(color: Colors.tealAccent)
                : Switch(
                    value: _isFounder,
                    activeColor: Colors.tealAccent,
                    onChanged: (value) => _updateUserRole(value),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(Map<String, dynamic> userData, List<String> startupNames) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow('Mobile', userData['mobileNumber']),
            _buildInfoRow('Country', userData['country']),
            _buildInfoRow('State', userData['state']),
            _buildInfoRow('Total Postings', startupNames.length.toString()),
          ],
        ),
      ),
    );
  }

  Widget _startupsCard(List<String> startupNames) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
            if (startupNames.isEmpty)
              Text(
                'No startups posted yet.',
                style: TextStyle(color: Colors.grey[400]),
              )
            else
              ...startupNames.map(
                (name) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $name',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
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

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.tealAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value != null && value.toString().isNotEmpty
                ? value.toString()
                : 'N/A',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
