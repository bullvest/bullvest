import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';
import 'package:bullvest/founder_dashboard.dart'; // adjust path if needed

class PostStartupForm extends StatefulWidget {
  @override
  _PostStartupFormState createState() => _PostStartupFormState();
}

class _PostStartupFormState extends State<PostStartupForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _stageController = TextEditingController();
  final TextEditingController _fundingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Add startup to 'portfolio'
      final newDoc =
          await FirebaseFirestore.instance.collection('portfolio').add({
        'uid': AppConstants.currentUser.id,
        'name': _nameController.text.trim(),
        'industry': _industryController.text.trim(),
        'stage': _stageController.text.trim(),
        'funding': _fundingController.text.trim(),
        'description': _descriptionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newStartupId = newDoc.id;

      // 2. Update user's `myPostingIDs` array
      await FirebaseFirestore.instance
          .collection('users')
          .doc(AppConstants.currentUser.id)
          .update({
        'myPostingIDs': FieldValue.arrayUnion([newStartupId]),
      });

      // 3. Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Startup posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // 4. Clear form fields
      _nameController.clear();
      _industryController.clear();
      _stageController.clear();
      _fundingController.clear();
      _descriptionController.clear();

      // 5. Redirect after a short delay
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } catch (e) {
      print('Error posting startup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post startup. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Your Startup'),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nameController, 'Startup Name'),
              SizedBox(height: 16),
              _buildTextField(_industryController, 'Industry'),
              SizedBox(height: 16),
              _buildTextField(
                  _stageController, 'Stage (Idea, MVP, Seed, etc.)'),
              SizedBox(height: 16),
              _buildTextField(
                  _fundingController, 'Funding Needed (e.g., \$100k)'),
              SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Brief Description',
                  maxLines: 4),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.black)
                    : Text('Post Startup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 18),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.tealAccent),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.tealAccent)),
      ),
      validator: (value) =>
          value!.isEmpty ? 'Please enter $label.toLowerCase()' : null,
    );
  }
}
