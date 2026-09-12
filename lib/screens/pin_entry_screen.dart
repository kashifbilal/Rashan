import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'household_list_screen.dart';

/// Shown every time the app opens (after the first run): enter the PIN to
/// unlock and see the household data.
class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinController = TextEditingController();
  final _authService = AuthService();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkPin() async {
    setState(() {
      _checking = true;
      _error = null;
    });

    final correct = await _authService.verifyPin(_pinController.text.trim());

    if (!mounted) return;

    if (correct) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HouseholdListScreen()),
      );
    } else {
      setState(() {
        _checking = false;
        _error = 'Incorrect PIN';
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Enter PIN to unlock',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(labelText: 'PIN'),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              onSubmitted: (_) => _checkPin(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checking ? null : _checkPin,
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
