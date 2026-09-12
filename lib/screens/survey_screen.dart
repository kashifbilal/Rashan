import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../db/database_helper.dart';
import '../models/household.dart';

/// Step 1 of the household survey: Identification & Composition, now with
/// GPS location capture and a household/ID photo.
///
/// Next steps (future messages) will add: livelihood questions, the
/// auto-calculated eligibility score, and delivery-confirmation fields.
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

  double? _latitude;
  double? _longitude;
  bool _capturingLocation = false;
  String? _locationError;

  File? _photoFile;
  bool _capturingPhoto = false;

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

  // ---------- Location capture ----------

  Future<void> _captureLocation() async {
    setState(() {
      _capturingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are turned off on this phone.';
          _capturingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission was denied.';
            _capturingLocation = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permission is permanently denied. Enable it in '
              'phone Settings > Apps > Rashan Survey > Permissions.';
          _capturingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _capturingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Could not get location: $e';
        _capturingLocation = false;
      });
    }
  }

  // ---------- Photo capture ----------

  Future<void> _capturePhoto() async {
    setState(() => _capturingPhoto = true);
    try {
      final picker = ImagePicker();
      final XFile? shot = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (shot == null) {
        setState(() => _capturingPhoto = false);
        return;
      }

      // Copy the photo into a permanent app folder so it survives even if
      // the camera app clears its own temporary files.
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'household_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final fileName = 'household_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile =
          await File(shot.path).copy(p.join(photosDir.path, fileName));

      setState(() {
        _photoFile = savedFile;
        _capturingPhoto = false;
      });
    } catch (e) {
      setState(() => _capturingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not capture photo: $e')),
        );
      }
    }
  }

  // ---------- Validation ----------

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
      latitude: _latitude,
      longitude: _longitude,
      photoPath: _photoFile?.path,
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
            const Text(
              'Section 2: Location & Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _capturingLocation ? null : _captureLocation,
              icon: const Icon(Icons.my_location),
              label: Text(
                _latitude == null
                    ? 'Capture GPS Location'
                    : 'Location captured — tap to recapture',
              ),
            ),
            if (_capturingLocation) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            if (_latitude != null && _longitude != null) ...[
              const SizedBox(height: 8),
              Text(
                'Lat: ${_latitude!.toStringAsFixed(6)}, '
                'Lng: ${_longitude!.toStringAsFixed(6)}',
                style: const TextStyle(color: Colors.green),
              ),
            ],
            if (_locationError != null) ...[
              const SizedBox(height: 8),
              Text(_locationError!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _capturingPhoto ? null : _capturePhoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(_photoFile == null ? 'Take Photo' : 'Retake Photo'),
            ),
            if (_photoFile != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _photoFile!,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ],

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
