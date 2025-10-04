import 'package:bullvest/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ContactModel {
  String? id;
  String? firstName;
  String? lastName;
  String? fullName;

  ContactModel({
    this.id = "",
    this.firstName = "",
    this.lastName = "",
  });

  String getFullNameOfUser() {
    return fullName = firstName! + " " + lastName!;
  }

  UserModel createUserFromContact() {
    return UserModel(
      id: id!,
      firstName: firstName!,
      lastName: lastName!,
    );
  }

  getContactInfoFromFirestore() async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').doc(id).get();

    firstName = snapshot['firstName'] ?? "";
    lastName = snapshot['lastName'] ?? "";
  }
}
