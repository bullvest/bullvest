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
  bool _isEditingProfile = false;

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
    final savedIDs = List<String>.from(userData['savedPostingIDs'] ?? []);

    List<Map<String, dynamic>> startupDetails = [];
    List<Map<String, dynamic>> startupDetail = [];

    if (postingIDs.isNotEmpty) {
      final portfolioSnapshots = await Future.wait(
        postingIDs.map(
          (id) =>
              FirebaseFirestore.instance.collection('portfolio').doc(id).get(),
        ),
      );

      startupDetails = portfolioSnapshots.where((doc) => doc.exists).map((doc) {
        final data = doc.data() ?? {};
        return {
          'id': doc.id, // Add the document ID here
          ...data, // Spread the rest of the data
        };
      }).toList();
    }

    if (savedIDs.isNotEmpty) {
      final startSnapshots = await Future.wait(
        savedIDs.map(
          (id) =>
              FirebaseFirestore.instance.collection('portfolio').doc(id).get(),
        ),
      );

      startupDetail = startSnapshots.where((doc) => doc.exists).map((doc) {
        final datas = doc.data() ?? {};
        return {
          'idd': doc.id, // Add the document ID here
          ...datas, // Spread the rest of the data
        };
      }).toList();
    }

    _isFounder = userData['type'] == 'founder';

    return {
      'userData': userData,
      'startupDetails': startupDetails,
      'startupDetail': startupDetail,
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
          final startupDetails =
              snapshot.data!['startupDetails'] as List<Map<String, dynamic>>;
          final startupDetail =
              snapshot.data!['startupDetail'] as List<Map<String, dynamic>>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _profileHeader(userData),
                const SizedBox(height: 24),
                _roleSwitchCard(),
                const SizedBox(height: 24),
                _infoCard(userData, startupDetails),
                const SizedBox(height: 24),
                // Only show startups section if there are startups
                if (startupDetails.isNotEmpty) _startupsSection(startupDetails),
                const SizedBox(height: 24),
                // Only show investments section if there are investments
                if (startupDetail.isNotEmpty) _investSection(startupDetail),
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
    return Stack(
      children: [
        // Main content of the profile header
        Row(
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
        ),

        // Positioned Edit button at the top-right corner
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: () async {
              setState(() {
                _isEditingProfile = true;
              });
              await _editProfile(userData);
              setState(() {
                _isEditingProfile = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black, // Black background for the button
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.tealAccent, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.edit,
                    color: Colors.tealAccent,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _infoCard(Map<String, dynamic> userData,
      List<Map<String, dynamic>> startupDetails) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child:
            // Card content (Info Rows)
            Column(
          children: [
            _buildInfoRow('Mobile', userData['mobileNumber']),
            _buildInfoRow('Country', userData['country']),
            _buildInfoRow('State', userData['state']),
            _buildInfoRow('Total Postings', startupDetails.length.toString()),
          ],
        ),
        // Positioned Edit button at the top-right corner
      ),
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
            ? Container()
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

  Widget _investSection(List<Map<String, dynamic>> investments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Investment Portfolio',
          style: TextStyle(
              color: Colors.tealAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        investments.isEmpty
            ? Container()
            : SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: investments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final startup = investments[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StartupDetailScreen(
                              startupId:
                                  startup['idd'], // For investment detail
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
}
