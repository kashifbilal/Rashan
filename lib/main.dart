import 'package:flutter/material.dart';
import 'screens/household_list_screen.dart';

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
      home: const HouseholdListScreen(),
    );
  }
}
