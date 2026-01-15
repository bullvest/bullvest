import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bullvest/model/app_constants.dart';
import 'package:bullvest/login_screen.dart';
import 'package:bullvest/investor/startup_detail.dart';

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

  Future<void> _editProfile(Map<String, dynamic> userData) async {
    final firstNameController =
        TextEditingController(text: userData['firstName']);
    final lastNameController =
        TextEditingController(text: userData['lastName']);
    final mobileController =
        TextEditingController(text: userData['mobileNumber']);
    final countryController = TextEditingController(text: userData['country']);
    final stateController = TextEditingController(text: userData['state']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.tealAccent),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField('First Name', firstNameController),
              _buildTextField('Last Name', lastNameController),
              _buildTextField('Mobile', mobileController),
              _buildTextField('Country', countryController),
              _buildTextField('State', stateController),
            ],
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
                  .update({
                'firstName': firstNameController.text.trim(),
                'lastName': lastNameController.text.trim(),
                'mobileNumber': mobileController.text.trim(),
                'country': countryController.text.trim(),
                'state': stateController.text.trim(),
              });
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.tealAccent),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.tealAccent),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
                const SizedBox(height: 20),
                _roleSwitchCard(),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _editProfile(userData),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _isFounder
                    ? _startupsSection(startups)
                    : _investorPortfolioSection(startups),
                const SizedBox(height: 32),
                _logoutButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

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
              _isFounder ? 'Founder' : 'Investor',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
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

  Widget _startupsSection(List<Map<String, dynamic>> startups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Startups',
          style: TextStyle(
              color: Colors.tealAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        startups.isEmpty
            ? Text(
                'No startups posted yet.',
                style: TextStyle(color: Colors.grey[400]),
              )
            : SizedBox(
                height: 160,
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

  Widget _investorPortfolioSection(List<Map<String, dynamic>> startups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Invested Startups',
          style: TextStyle(
              color: Colors.tealAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        startups.isEmpty
            ? Text(
                'No startups invested yet.',
                style: TextStyle(color: Colors.grey[400]),
              )
            : SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: startups.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final startup = startups[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StartupDetailScreen(
                              startupId: startup['id'],
                            ),
                          ),
                        );
                      },
                      child: _startupCard(startup),
                    );
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
