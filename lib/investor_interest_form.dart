import 'package:flutter/material.dart';

class InvestorInterestForm extends StatefulWidget {
  @override
  _InvestorInterestFormState createState() => _InvestorInterestFormState();
}

class _InvestorInterestFormState extends State<InvestorInterestForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _sectorController = TextEditingController();
  final TextEditingController _ticketSizeController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _interestNoteController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Replace this with backend logic later
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferences saved successfully!')),
      );

      // Clear form
      _sectorController.clear();
      _ticketSizeController.clear();
      _regionController.clear();
      _interestNoteController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Investment Preferences'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _sectorController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preferred Sectors (e.g. Fintech, Healthtech)',
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.tealAccent)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter at least one sector' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _ticketSizeController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Ticket Size (e.g. \$50k - \$250k)',
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.tealAccent)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter ticket size range' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _regionController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preferred Regions (e.g. Nigeria, Africa)',
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.tealAccent)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter preferred regions' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _interestNoteController,
                style: TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Other Interests / Notes',
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.tealAccent)),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Preferences'),
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
