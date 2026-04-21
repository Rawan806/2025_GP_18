import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations_helper.dart';

class SearchMatchItemsPage extends StatefulWidget {
  final Map<String, dynamic>? initialCreatedDoc;

  const SearchMatchItemsPage({super.key, this.initialCreatedDoc});

  @override
  State<SearchMatchItemsPage> createState() => _SearchMatchItemsPageState();
}

class _SearchMatchItemsPageState extends State<SearchMatchItemsPage> {
  final Color mainGreen = const Color(0xFF243E36);
  final String baseUrl = 'http://192.168.1.119:8000';

  String _tr(String key) {
    final locale = Localizations.localeOf(context);
    return AppLocalizations.translate(key, locale.languageCode);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMatchingFlow());
  }

  String _resolveSearchDocId(Map<String, dynamic> doc) {
    final firebaseDocId = (doc['firebaseDocId'] ?? '').toString();
    if (firebaseDocId.isNotEmpty && firebaseDocId != 'null') return firebaseDocId;

    final docId = (doc['id'] ?? doc['docId'] ?? '').toString();
    if (docId.isNotEmpty && docId != 'null') return docId;

    final docNum = (doc['doc_num'] ?? '').toString();
    return docNum;
  }

  Future<void> _startMatchingFlow() async {
    final report = widget.initialCreatedDoc;
    if (report == null) {
      return;
    }

    final docId = _resolveSearchDocId(report);
    if (docId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('noDocIdFoundForSearch')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final requestBody = <String, dynamic>{
      'docId': docId,
      'top_k': 5,
    };

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MatchResultsPage(
          selectedDocId: docId,
          baseUrl: baseUrl,
          initialRequestBody: requestBody,
          mainGreen: mainGreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC3BFB0),
      appBar: AppBar(
        backgroundColor: mainGreen,
        centerTitle: true,
        title: Text(
          _tr('matching'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: widget.initialCreatedDoc == null
            ? Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  _tr('noItemPassedForMatching'),
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: mainGreen),
                  const SizedBox(height: 12),
                  Text(_tr('searchingSimilarItemsMessage')),
                ],
              ),
      ),
    );
  }
}

class MatchResultsPage extends StatefulWidget {
  const MatchResultsPage({
    super.key,
    required this.selectedDocId,
    required this.baseUrl,
    required this.initialRequestBody,
    required this.mainGreen,
  });

  final String selectedDocId;
  final String baseUrl;
  final Map<String, dynamic> initialRequestBody;
  final Color mainGreen;

  @override
  State<MatchResultsPage> createState() => _MatchResultsPageState();
}

class _MatchResultsPageState extends State<MatchResultsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _results = [];

  String _tr(String key) {
    final locale = Localizations.localeOf(context);
    return AppLocalizations.translate(key, locale.languageCode);
  }

  @override
  void initState() {
    super.initState();
    _fetchMatchesForReport();
  }

  Future<void> _fetchMatchesForReport() async {
    final requestBody = Map<String, dynamic>.from(widget.initialRequestBody);
    requestBody['docId'] = widget.selectedDocId;
    requestBody['top_k'] = 5;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
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

      setState(() {
        _results = rawResults.take(5).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(child: Icon(Icons.image_not_supported)),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              '${_tr(label)}:',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ]
      ),
    );
  }

  Future<void> _showResultDetails(Map<String, dynamic> result) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        final image = (result['imageUrl'] ?? '').toString();
        final matchedDocId = (result['docId'] ?? '').toString();

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _tr('matchDetails'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (image.isNotEmpty)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          image,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 150,
                            height: 150,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailRow('idLabel', matchedDocId),
                            _detailRow(
                              'similarity',
                              '${(((result['similarity'] ?? 0) as num).toDouble() * 100).toStringAsFixed(2)}%',
                            ),
                            _detailRow('type', (result['collection'] ?? '').toString()),
                            _detailRow('matchCategory', (result['category'] ?? '').toString()),
                            _detailRow('date', (result['date'] ?? '').toString()),
                            _detailRow('status', (result['status'] ?? '').toString()),
                            _detailRow('color', (result['color'] ?? '').toString()),
                            _detailRow('location', (result['location'] ?? '').toString()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          final docRef = FirebaseFirestore.instance
                              .collection('foundItems')
                              .doc(widget.selectedDocId);
                          await docRef.update({'status': 'stored'});
                        } catch (_) {}

                        if (!mounted) return;
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B4ABF),
                        side: const BorderSide(color: Color(0xFF5B4ABF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_tr('noSuitableMatch')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.mainGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);

                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(_tr('confirmAndSend')),
                            content: Text(_tr('confirmMatchAndSendQuestion')),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(_tr('no')),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.mainGreen,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(_tr('confirmAndSend')),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true) return;

                        try {
                          await FirebaseFirestore.instance
                              .collection('linkedLostReportId')
                              .add({
                            'found_doc_id': widget.selectedDocId,
                            'matched_doc_id': matchedDocId,
                            'createdAt': Timestamp.now(),
                          });

                          final locale = Localizations.localeOf(context);
                          await FirebaseFirestore.instance
                              .collection('foundItems')
                              .doc(widget.selectedDocId)
                              .update({
                            'status': AppLocalizations.translate('sent_to_user', locale.languageCode),
                          });

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_tr('matchConfirmedAndSaved')),
                              backgroundColor: Colors.green,
                            ),
                          );

                          Navigator.pop(context);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${_tr('errorSavingMatch')}: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(_tr('selectThisMatch')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item, int index) {
    final docId = (item['docId'] ?? '').toString();
    final image = (item['imageUrl'] ?? '').toString();
    final similarity = ((item['similarity'] ?? 0) as num).toDouble();
    final isBest = index == 0;

    return InkWell(
      onTap: () => _showResultDetails(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isBest ? const Color(0xFFEFF8F0) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isBest ? Colors.green.shade400 : Colors.transparent,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
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
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    docId,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.mainGreen,
                    ),
                  ),
                  Text('${_tr('type')}: ${(item['collection'] ?? '').toString()}'),
                  Text('${_tr('date')}: ${(item['date'] ?? '-').toString()}'),
                  Text(
                    '${_tr('similarity')}: ${(similarity * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (isBest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _tr('bestMatch'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC3BFB0),
      appBar: AppBar(
        backgroundColor: widget.mainGreen,
        title: Text(
          _tr('matchingResults'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.mainGreen))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _results.isEmpty
                  ? Center(child: Text(_tr('noMatchingResultsReturned')))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _buildResultCard(_results[index], index);
                      },
                    ),
    );
  }
}
