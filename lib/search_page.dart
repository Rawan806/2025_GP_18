import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _docIdController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _searchResponse;
  int? _selectedIndex;

  final String baseUrl = 'http://10.0.2.2:8000';

  Future<void> searchByDocId() async {
    final docId = _docIdController.text.trim();

    if (docId.isEmpty) {
      setState(() {
        _errorMessage = 'Enter docId';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResponse = null;
      _selectedIndex = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'docId': docId, 'top_k': 5}),
      );

      final data = jsonDecode(response.body);

      setState(() {
        _searchResponse = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color getMatchColor(String label) {
    switch (label) {
      case 'strong_match':
        return Colors.green;
      case 'potential_match':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  void confirmMatch() {
    if (_selectedIndex == null) return;

    final selected = _searchResponse!['results'][_selectedIndex!];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Match Confirmed"),
        content: Text("Matched with: ${selected['docId']}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _searchResponse?['results'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Employee Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _docIdController,
              decoration: const InputDecoration(
                labelText: "Enter Lost/Found docId",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isLoading ? null : searchByDocId,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Search"),
            ),

            const SizedBox(height: 12),

            if (_searchResponse != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Top Score: ${_searchResponse!['top_score']?.toStringAsFixed(3)}",
                      ),
                      Text(
                        "Avg: ${_searchResponse!['avg_top5_score']?.toStringAsFixed(3)}",
                      ),
                      Text("Latency: ${_searchResponse!['search_time_ms']} ms"),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  final label = item['match_label'];
                  final isSelected = _selectedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Card(
                      color: isSelected ? Colors.blue.shade50 : null,
                      child: Row(
                        children: [
                          Image.network(
                            item['imageUrl'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['docId'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text("Type: ${item['type']}"),
                                Text("Color: ${item['color']}"),
                                Text(
                                  "Similarity: ${item['similarity'].toStringAsFixed(3)}",
                                ),
                              ],
                            ),
                          ),

                          Icon(Icons.circle, color: getMatchColor(label)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_selectedIndex != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: confirmMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("Confirm Match"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
