import 'package:flutter/material.dart';
import 'package:people_desk/services/api_service.dart';

class RecruitmentScreen extends StatefulWidget {
  const RecruitmentScreen({super.key});

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  final _api = ApiService();
  List<dynamic> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await _api.getJobs();
      setState(() { _jobs = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recruitment')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? const Center(child: Text('No job postings'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _jobs.length,
                  itemBuilder: (_, i) {
                    final j = _jobs[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.work_outline, color: Colors.blue),
                        title: Text(j['title'] ?? ''),
                        subtitle: Text('${j['department'] ?? ''} \u2022 ${j['employment_type']}'),
                        trailing: Chip(
                          label: Text(j['status'] ?? 'open', style: const TextStyle(fontSize: 12)),
                          backgroundColor: (j['status'] == 'open') ? Colors.green.shade100 : Colors.grey.shade200,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
