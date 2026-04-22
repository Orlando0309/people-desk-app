import 'package:flutter/material.dart';
import 'package:people_desk/services/api_service.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final _api = ApiService();
  List<dynamic> _programs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await _api.getTrainingPrograms();
      setState(() { _programs = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _programs.isEmpty
              ? const Center(child: Text('No training programs'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _programs.length,
                  itemBuilder: (_, i) {
                    final p = _programs[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.school, color: Colors.indigo),
                        title: Text(p['title'] ?? ''),
                        subtitle: Text('${p['provider'] ?? ''} \u2022 ${p['duration']} ${p['duration_unit']}'),
                        trailing: Chip(
                          label: Text(p['status'] ?? 'active', style: const TextStyle(fontSize: 12)),
                          backgroundColor: (p['status'] == 'active') ? Colors.green.shade100 : Colors.grey.shade200,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
