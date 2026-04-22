import 'package:flutter/material.dart';
import 'package:people_desk/services/api_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _api = ApiService();
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await _api.getExpenses();
      setState(() { _items = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No expenses'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final e = _items[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long, color: Colors.teal),
                        title: Text('${e['category']} - ${e['amount']} ${e['currency'] ?? 'MGA'}'),
                        subtitle: Text('${e['date']?.toString().substring(0, 10) ?? ''}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(e['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            e['status'].toUpperCase(),
                            style: TextStyle(color: _statusColor(e['status']), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
