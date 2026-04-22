import 'package:flutter/material.dart';
import 'package:people_desk/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _api = ApiService();
  List<dynamic> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await _api.getDocuments();
      setState(() { _docs = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack(e.toString());
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _docs.isEmpty
              ? const Center(child: Text('No documents'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _docs.length,
                  itemBuilder: (_, i) {
                    final d = _docs[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.description, color: Colors.deepPurple),
                        title: Text(d['name'] ?? ''),
                        subtitle: Text('${d['category']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () async {
                            final url = Uri.parse(d['file_url'] ?? '');
                            if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
