import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/household.dart';

/// Step 1 of the household survey: Identification & Composition.
///
/// Next steps (future messages) will add more sections to this same flow:
/// GPS capture, livelihood questions, photo/voice capture, and the
/// auto-calculated eligibility score — each as its own screen/section that
/// plugs into this one.
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _surveyorController = TextEditingController();
  final _nameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _familySizeController = TextEditingController();
  final _childrenController = TextEditingController();
  final _elderlyController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _surveyorController.dispose();
    _nameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _familySizeController.dispose();
    _childrenController.dispose();
    _elderlyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateCnic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CNIC is required';
    }
    final digitsOnly = value.replaceAll('-', '');
    if (digitsOnly.length != 13 || int.tryParse(digitsOnly) == null) {
      return 'Enter a valid 13-digit CNIC (e.g. 12345-1234567-1)';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final n = int.tryParse(value);
    if (n == null || n < 0) {
      return 'Enter a valid number for $fieldName';
    }
    return null;
  }

  Future<void> _submitSurvey() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cnic = _cnicController.text.trim();
    final alreadyExists = await DatabaseHelper.instance.cnicExists(cnic);

    if (alreadyExists && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplicate CNIC'),
          content: const Text(
            'A household with this CNIC has already been surveyed. '
            'Save this entry anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isSaving = true);

    final household = Household(
      surveyorName: _surveyorController.text.trim(),
      surveyDate: DateTime.now(),
      headOfHouseholdName: _nameController.text.trim(),
      cnic: cnic,
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      totalFamilyMembers: int.parse(_familySizeController.text.trim()),
      childrenUnder18: int.parse(_childrenController.text.trim()),
      elderlyOver60: int.parse(_elderlyController.text.trim()),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await DatabaseHelper.instance.insertHousehold(household);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Household saved successfully')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Household Survey')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Section 1: Identification & Composition',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _surveyorController,
              decoration: const InputDecoration(labelText: 'Surveyor Name'),
              validator: (v) => _validateRequired(v, 'Surveyor name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: 'Head of Household Name'),
              validator: (v) =>
                  _validateRequired(v, 'Head of household name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cnicController,
              decoration: const InputDecoration(
                labelText: 'CNIC',
                hintText: '12345-1234567-1',
              ),
              keyboardType: TextInputType.number,
              validator: _validateCnic,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (v) => _validateRequired(v, 'Phone number'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address / Area'),
              maxLines: 2,
              validator: (v) => _validateRequired(v, 'Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _familySizeController,
              decoration:
                  const InputDecoration(labelText: 'Total Family Members'),
              keyboardType: TextInputType.number,
              validator: (v) => _validateNumber(v, 'total family members'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _childrenController,
              decoration:
                  const InputDecoration(labelText: 'Children Under 18'),
              keyboardType: TextInputType.number,
              validator: (v) => _validateNumber(v, 'children under 18'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _elderlyController,
              decoration: const InputDecoration(labelText: 'Elderly (60+)'),
              keyboardType: TextInputType.number,
              validator: (v) => _validateNumber(v, 'elderly count'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _submitSurvey,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Household'),
            ),
          ],
        ),
      ),
    );
  }
}
