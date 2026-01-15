import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bullvest/model/app_constants.dart';

class PostStartupForm extends StatefulWidget {
  const PostStartupForm({Key? key}) : super(key: key);

  @override
  _PostStartupFormState createState() => _PostStartupFormState();
}

class _PostStartupFormState extends State<PostStartupForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _stageController = TextEditingController();
  final TextEditingController _fundingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _problemController = TextEditingController();
  final TextEditingController _solutionController = TextEditingController();
  final TextEditingController _pitchDeckController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _teamSizeController = TextEditingController();
  final TextEditingController _marketController = TextEditingController();

  String _selectedCurrency = '₦'; // ✅ Currency dropdown
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final fundingAmount =
          int.tryParse(_fundingController.text.replaceAll(',', ''));

      if (fundingAmount == null) {
        throw 'Invalid funding amount';
      }

      // 1️⃣ Add startup to portfolio
      final docRef =
          await FirebaseFirestore.instance.collection('portfolio').add({
        'uid': AppConstants.currentUser.id,
        'name': _nameController.text.trim(),
        'industry': _industryController.text.trim(),
        'stage': _stageController.text.trim(),
        'funding': fundingAmount, // ✅ numeric
        'currency': _selectedCurrency, // ✅ saved
        'description': _descriptionController.text.trim(),
        'problem': _problemController.text.trim(),
        'solution': _solutionController.text.trim(),
        'pitchDeckUrl': _pitchDeckController.text.trim(),
        'website': _websiteController.text.trim(),
        'teamSize': _teamSizeController.text.trim(),
        'targetMarket': _marketController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open', // ✅ default status
      });

      // 2️⃣ Track posting under user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(AppConstants.currentUser.id)
          .update({
        'myPostingIDs': FieldValue.arrayUnion([docRef.id])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Startup posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
      setState(() => _selectedCurrency = '₦');

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } catch (e) {
      debugPrint('Error posting startup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to post startup. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(color: Colors.tealAccent),
        hintStyle: const TextStyle(color: Colors.grey),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.tealAccent),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _currencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCurrency,
      dropdownColor: Colors.grey[900],
      decoration: const InputDecoration(
        labelText: 'Currency',
        labelStyle: TextStyle(color: Colors.tealAccent),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.tealAccent),
        ),
      ),
      items: const [
        DropdownMenuItem(value: '₦', child: Text('₦ Nigerian Naira')),
        DropdownMenuItem(value: '\$', child: Text('\$ US Dollar')),
        DropdownMenuItem(value: '€', child: Text('€ Euro')),
        DropdownMenuItem(value: '£', child: Text('£ British Pound')),
      ],
      onChanged: (value) {
        setState(() => _selectedCurrency = value!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Post Your Startup'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nameController, 'Startup Name'),
              const SizedBox(height: 12),
              _buildTextField(_industryController, 'Industry / Sector'),
              const SizedBox(height: 12),
              _buildTextField(
                _stageController,
                'Stage (Idea, MVP, Seed, Growth)',
              ),
              const SizedBox(height: 12),
              _currencyDropdown(),
              const SizedBox(height: 12),
              _buildTextField(
                _fundingController,
                'Funding Needed',
                keyboardType: TextInputType.number,
                hintText: 'e.g. 100000',
              ),
              const SizedBox(height: 12),
              _buildTextField(_teamSizeController, 'Team Size'),
              const SizedBox(height: 12),
              _buildTextField(_marketController, 'Target Market'),
              const SizedBox(height: 12),
              _buildTextField(
                _problemController,
                'Problem Statement',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _solutionController,
                'Solution / Value Proposition',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _descriptionController,
                'Brief Description',
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _pitchDeckController,
                'Pitch Deck URL',
                hintText: 'Google Drive / PDF link',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _websiteController,
                'Website / Social Link',
                hintText: 'Optional',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Post Startup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
