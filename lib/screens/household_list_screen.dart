import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/household.dart';
import 'survey_screen.dart';

/// The app's home screen: shows every household surveyed so far, and lets
/// you start a new survey. This is the screen you'll land on when you open
/// the app.
class HouseholdListScreen extends StatefulWidget {
  const HouseholdListScreen({super.key});

  @override
  State<HouseholdListScreen> createState() => _HouseholdListScreenState();
}

class _HouseholdListScreenState extends State<HouseholdListScreen> {
  List<Household> _households = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHouseholds();
  }

  Future<void> _loadHouseholds() async {
    setState(() => _loading = true);
    final households = await DatabaseHelper.instance.getAllHouseholds();
    setState(() {
      _households = households;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rashan Household Survey')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _households.isEmpty
              ? const Center(child: Text('No households surveyed yet.'))
              : ListView.builder(
                  itemCount: _households.length,
                  itemBuilder: (context, index) {
                    final h = _households[index];
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(h.headOfHouseholdName),
                        subtitle: Text(
                          'CNIC: ${h.cnic}\n'
                          'Family size: ${h.totalFamilyMembers} '
                          '(Children: ${h.childrenUnder18}, Elderly: ${h.elderlyOver60})\n'
                          'Surveyed by ${h.surveyorName} on '
                          '${h.surveyDate.day}/${h.surveyDate.month}/${h.surveyDate.year}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SurveyScreen()),
          );
          if (saved == true) {
            _loadHouseholds();
          }
        },
        tooltip: 'New Survey',
        child: const Icon(Icons.add),
      ),
    );
  }
}
