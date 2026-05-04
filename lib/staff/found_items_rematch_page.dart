import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_localizations_helper.dart';
import 'search_match_items_page.dart';

class FoundItemsRematchPage extends StatefulWidget {
  const FoundItemsRematchPage({
    super.key,
    required this.foundItems,
    required this.mainGreen,
  });

  final List<Map<String, dynamic>> foundItems;
  final Color mainGreen;

  @override
  State<FoundItemsRematchPage> createState() => _FoundItemsRematchPageState();
}

class _FoundItemsRematchPageState extends State<FoundItemsRematchPage> {
  final String baseUrl = 'http://192.168.1.106:8000';

  bool _isLoading = true;
  String? _errorMessage;
  int _processedCount = 0;
  List<_MatchedFoundItem> _matchedItems = [];

  @override
  void initState() {
    super.initState();
    _runRematching();
  }

  String _tr(String key) {
    final locale = Localizations.localeOf(context);
    return AppLocalizations.translate(key, locale.languageCode);
  }

  Future<List<Map<String, dynamic>>> _searchMatchesForItem(String docId) async {
    final requestBody = <String, dynamic>{
      'docId': docId,
      'top_k': 5,
    };

    debugPrint(
      'FoundItemsRematchPage: Attempting to connect to AI backend at: $baseUrl/search',
    );

    final response = await http
        .post(
          Uri.parse('$baseUrl/search'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 10));

    debugPrint(
      'FoundItemsRematchPage: Received response from AI: ${response.statusCode}',
    );

    if (response.statusCode >= 400) {
      throw Exception('Server error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawResults = (data['results'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    rawResults.sort((a, b) {
      final simA = (a['similarity'] as num?) ?? 0;
      final simB = (b['similarity'] as num?) ?? 0;
      return simB.compareTo(simA);
    });

    return rawResults.take(5).toList();
  }

  Future<void> _runRematching() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _processedCount = 0;
      _matchedItems = [];
    });

    final matchedItems = <_MatchedFoundItem>[];

    try {
      for (final item in widget.foundItems) {
        final docId = (item['docId'] ?? item['id'] ?? '').toString();
        if (docId.isEmpty) {
          if (!mounted) return;
          setState(() => _processedCount += 1);
          continue;
        }

        try {
          final results = await _searchMatchesForItem(docId);

          if (results.isNotEmpty) {
            matchedItems.add(
              _MatchedFoundItem(
                report: item,
                matchCount: results.length,
                topSimilarity: ((results.first['similarity'] as num?) ?? 0)
                    .toDouble(),
              ),
            );
          }
        } catch (_) {
          // Ignore per-item failures so the remaining items can still be checked.
        }

        if (!mounted) return;
        setState(() => _processedCount += 1);
      }

      if (!mounted) return;
      setState(() {
        _matchedItems = matchedItems;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _buildDateLabel(Map<String, dynamic> report) {
    final raw = report['date']?.toString();
    if (raw != null && raw.isNotEmpty) return raw;

    final foundAt = report['foundAt'];
    if (foundAt is! dynamic) return '-';
    return foundAt.toString();
  }

  void _openSearchMatches(Map<String, dynamic> report) {
    final docId = (report['docId'] ?? report['id'] ?? '').toString();
    if (docId.isEmpty) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SearchMatchItemsPage(
          initialCreatedDoc: {
            'firebaseDocId': docId,
            'id': docId,
            'doc_num': (report['doc_num'] ?? '').toString(),
            'collection': 'foundItems',
            '_key': 'found:$docId',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFC3BFB0),
        appBar: AppBar(
          backgroundColor: widget.mainGreen,
          foregroundColor: Colors.white,
          title: Text(
            isArabic ? 'إعادة مطابقة المعثورات' : 'Rematch Found Items',
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: widget.mainGreen),
                    const SizedBox(height: 12),
                    Text(
                      isArabic
                          ? 'جاري فحص العناصر $_processedCount من ${widget.foundItems.length}'
                          : 'Checking items $_processedCount of ${widget.foundItems.length}',
                    ),
                  ],
                ),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            : _matchedItems.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    isArabic
                        ? 'لم يتم العثور على عناصر معثور عليها لها تطابقات حالياً'
                        : 'No stored found items have matches right now',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _matchedItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _matchedItems[index];
                  final report = item.report;
                  final title = (report['title'] ?? report['type'] ?? '-')
                      .toString();
                  final docId = (report['doc_num'] ?? report['docId'] ?? '-')
                      .toString();
                  final imageUrl =
                      (report['imagePath'] ?? report['imageUrl'] ?? '')
                          .toString();

                  return InkWell(
                    onTap: () => _openSearchMatches(report),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#$docId',
                                  style: TextStyle(
                                    color: widget.mainGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_tr('date')}: ${_buildDateLabel(report)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.mainGreen.withOpacity(
                                          0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isArabic
                                            ? '${item.matchCount} تطابق'
                                            : '${item.matchCount} matches',
                                        style: TextStyle(
                                          color: widget.mainGreen,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_tr('similarity')}: ${(item.topSimilarity * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _MatchedFoundItem {
  const _MatchedFoundItem({
    required this.report,
    required this.matchCount,
    required this.topSimilarity,
  });

  final Map<String, dynamic> report;
  final int matchCount;
  final double topSimilarity;
}
