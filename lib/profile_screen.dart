import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bullvest/model/app_constants.dart';
import 'package:bullvest/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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
        postingIDs.map((id) =>
            FirebaseFirestore.instance.collection('portfolio').doc(id).get()),
      );

      startupNames = portfolioSnapshots
          .where((doc) => doc.exists)
          .map((doc) => doc.data()?['name'] ?? 'Untitled')
          .cast<String>()
          .toList();
    }

    return {
      'userData': userData,
      'startupNames': startupNames,
    };
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserDataWithStartups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Failed to load profile data.',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final userData = snapshot.data!['userData'] as Map<String, dynamic>;
          final startupNames = snapshot.data!['startupNames'] as List<String>;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('First Name', userData['firstName']),
                _buildInfoRow('Last Name', userData['lastName']),
                _buildInfoRow('Type', userData['type']),
                _buildInfoRow('Mobile Number', userData['mobileNumber']),
                _buildInfoRow('Email', userData['email']),
                _buildInfoRow('Country', userData['country']),
                _buildInfoRow('State', userData['state']),
                _buildInfoRow('Number of Postings', '${startupNames.length}'),
                SizedBox(height: 20),
                Text(
                  'Your Startups:',
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                startupNames.isEmpty
                    ? Text(
                        'No startups posted yet.',
                        style: TextStyle(color: Colors.grey[400]),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: startupNames.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                '- ${startupNames[index]}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      textStyle:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: Text('Log Out'),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 16, color: Colors.white),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.tealAccent),
            ),
            TextSpan(
              text: value != null && value.toString().isNotEmpty
                  ? value.toString()
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }
}
