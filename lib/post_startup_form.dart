import 'package:flutter/material.dart';

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // For now, just show a success snackbar (replace with backend call later)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Startup posted successfully!')),
      );

      // Clear form
      _nameController.clear();
      _industryController.clear();
      _stageController.clear();
      _fundingController.clear();
      _descriptionController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Your Startup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Startup Name',
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.tealAccent)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter startup name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _industryController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Industry',
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.tealAccent)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter industry' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _stageController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Stage (Idea, MVP, Seed, Series A, etc.)',
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.tealAccent)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter startup stage' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _fundingController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Funding Needed (e.g., \$100k)',
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.tealAccent)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter funding amount' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Brief Description',
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.tealAccent)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter description' : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Post Startup'),
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
}
