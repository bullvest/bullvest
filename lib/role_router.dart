import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';
import 'investor/investor_nav.dart';
import 'founder/founder_nav.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(AppConstants.currentUser.id)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data!['type'];

        return role == 'founder'
            ? const FounderBottomNav()
            : const InvestorBottomNav();
      },
    );
  }
}
