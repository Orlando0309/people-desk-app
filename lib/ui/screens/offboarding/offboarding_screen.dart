import 'package:flutter/material.dart';
import 'package:people_desk/services/api_service.dart';

class OffboardingScreen extends StatefulWidget {
  const OffboardingScreen({super.key});

  @override
  State<OffboardingScreen> createState() => _OffboardingScreenState();
}

class _OffboardingScreenState extends State<OffboardingScreen> {
  final _api = ApiService();
  List<dynamic> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await _api.getOffboardingRecords();
      setState(() { _records = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  double _checklistProgress(dynamic r) {
    int done = 0;
    if (r['notice_period_served'] == true) done++;
    if (r['company_assets_returned'] == true) done++;
    if (r['data_handover_complete'] == true) done++;
    if (r['final_payroll_processed'] == true) done++;
    if (r['benefits_terminated'] == true) done++;
    return done / 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offboarding')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('No offboarding records'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  itemBuilder: (_, i) {
                    final r = _records[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    r['reason'].toString().replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Chip(
                                  label: Text(r['status'] ?? 'in_progress', style: const TextStyle(fontSize: 12)),
                                  backgroundColor: (r['status'] == 'completed') ? Colors.green.shade100 : Colors.orange.shade100,
                                ),
                              ],
                            ),
                            Text('Last day: ${r['last_working_date']?.toString().substring(0,10) ?? ''}'),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: _checklistProgress(r), minHeight: 6),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
