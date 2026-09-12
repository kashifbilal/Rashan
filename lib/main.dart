import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/pin_setup_screen.dart';
import 'screens/pin_entry_screen.dart';

void main() {
  runApp(const RashanApp());
}

class RashanApp extends StatelessWidget {
  const RashanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rashan Survey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const StartupGate(),
    );
  }
}

/// Decides what the person sees when the app opens: if no PIN has ever been
/// set on this device, walk them through setting one; otherwise, ask for it.
class StartupGate extends StatelessWidget {
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isPinSet(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data! ? const PinEntryScreen() : const PinSetupScreen();
      },
    );
  }
}
