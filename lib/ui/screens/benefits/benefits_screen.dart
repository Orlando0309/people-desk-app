import 'package:flutter/material.dart';
import 'package:people_desk/services/api_service.dart';

class BenefitsScreen extends StatefulWidget {
  const BenefitsScreen({super.key});

  @override
  State<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends State<BenefitsScreen> {
  final _api = ApiService();
  List<dynamic> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await _api.getBenefitPlans();
      setState(() { _plans = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Benefits')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? const Center(child: Text('No benefit plans'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _plans.length,
                  itemBuilder: (_, i) {
                    final p = _plans[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.pink),
                        title: Text(p['name'] ?? ''),
                        subtitle: Text('${p['type']} \u2022 ${p['provider'] ?? 'N/A'}'),
                        trailing: Text('${p['cost'].toString()} ${p['currency'] ?? 'MGA'}'),
                      ),
                    );
                  },
                ),
    );
  }
}
