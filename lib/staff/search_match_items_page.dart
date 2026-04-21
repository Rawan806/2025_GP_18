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
  final String baseUrl = 'http://192.168.1.107:8000';

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
        const SnackBar(
          content: Text('لم يتم العثور على معرف المستند للبحث.'),
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
        title: const Text(
          'Matching',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: widget.initialCreatedDoc == null
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'لم يتم تمرير عنصر للبحث عن المطابقات.',
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: mainGreen),
                  const SizedBox(height: 12),
                  const Text('تم ارسال الطلب الى السيرفر للبحث عن العناصر المتشابهة...'),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }

  Future<void> _showResultDetails(Map<String, dynamic> result) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        final image = (result['imageUrl'] ?? '').toString();
        final matchedDocId = (result['docId'] ?? '').toString();

        return AlertDialog(
          title: const Text('Match Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (image.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      image,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                _detailRow('ID', matchedDocId),
                _detailRow(
                  'Similarity',
                  '${(((result['similarity'] ?? 0) as num).toDouble() * 100).toStringAsFixed(2)}%',
                ),
                _detailRow('Type', (result['collection'] ?? '').toString()),
                _detailRow('Category', (result['category'] ?? '').toString()),
                _detailRow('Date', (result['date'] ?? '').toString()),
                _detailRow('Status', (result['status'] ?? '').toString()),
                _detailRow('Color', (result['color'] ?? '').toString()),
                _detailRow('Location', (result['location'] ?? '').toString()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final docRef = FirebaseFirestore.instance
                      .collection('foundItems')
                      .doc(widget.selectedDocId);
                  // final snap = await docRef.get();
                  // final currentStatus =
                  //     (snap.data()?['status'] ?? '').toString().toLowerCase();

                  // if (currentStatus.contains('under review') ||
                  //     currentStatus.contains('قيد المراجعة')||
                  //     currentStatus.contains('send_to_user')
                  //     ) {
                  // }
                    await docRef.update({'status': 'stored'});
                } catch (_) {}

                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('No Suitable Match'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: widget.mainGreen),
              onPressed: () async {
                Navigator.pop(context);

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Confirm & Send'),
                    content: const Text('هل تريد تأكيد هذه المطابقة وإرسالها؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('لا'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.mainGreen,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Confirm & Send'),
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
                      .update({'status': AppLocalizations.translate('sent_to_user', locale.languageCode)});

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Match confirmed and saved'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving match: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Select This Match'),
            ),
          ],
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
                  Text('Type: ${(item['collection'] ?? '').toString()}'),
                  Text('Date: ${(item['date'] ?? '-').toString()}'),
                  Text(
                    'Similarity: ${(similarity * 100).toStringAsFixed(1)}%',
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
                child: const Text(
                  'Best',
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
        title: const Text(
          'Matching Results',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  ? const Center(child: Text('No matching results returned'))
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
