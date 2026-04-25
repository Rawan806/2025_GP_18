import 'dart:convert';
import 'dart:math';

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

    final docId = (doc['docId'] ?? doc['id'] ?? '').toString();
    if (docId.isNotEmpty && docId != 'null') return docId;

    final docNum = (doc['doc_num'] ?? '').toString();
    return docNum;
  }

  String _resolveApiCollection(Map<String, dynamic> doc) {
    final apiCollection = (doc['apiCollection'] ?? '').toString();
    if (apiCollection == 'lostItems' || apiCollection == 'foundItems') {
      return apiCollection;
    }

    final collection = (doc['collection'] ?? '').toString();
    if (collection == 'lost') return 'lostItems';
    if (collection == 'found') return 'foundItems';
    if (collection == 'lostItems' || collection == 'foundItems') {
      return collection;
    }

    final itemCategory = (doc['itemCategory'] ?? '').toString();
    if (itemCategory == 'lost') return 'lostItems';
    if (itemCategory == 'found') return 'foundItems';

    return 'foundItems';
  }

  Future<void> _startMatchingFlow() async {
    final report = widget.initialCreatedDoc;
    if (report == null) return;

    final docId = _resolveSearchDocId(report);
    final collection = _resolveApiCollection(report);

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

    final requestBody = {
      'docId': docId,
      'collection': collection,
      'top_k': 5,
    };

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MatchResultsPage(
          selectedDocId: docId,
          selectedCollection: collection,
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
          padding: const EdgeInsets.all(16),
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
    required this.selectedCollection,
    required this.baseUrl,
    required this.initialRequestBody,
    required this.mainGreen,
  });

  final String selectedDocId;
  final String selectedCollection;
  final String baseUrl;
  final Map<String, dynamic> initialRequestBody;
  final Color mainGreen;

  @override
  State<MatchResultsPage> createState() => _MatchResultsPageState();
}

class _MatchResultsPageState extends State<MatchResultsPage> {
  bool _isLoading = true;
  bool _isActionLoading = false;

  String? _errorMessage;
  List<Map<String, dynamic>> _results = [];

  String? _selectedResultDocId;
  Map<String, dynamic>? _confirmedMatch;

  String _tr(String key) {
    final locale = Localizations.localeOf(context);
    return AppLocalizations.translate(key, locale.languageCode);
  }

  @override
  void initState() {
    super.initState();
    _fetchMatchesForReport();
  }

  // =========================
  // API Search
  // =========================
  Future<void> _fetchMatchesForReport() async {
    final requestBody = Map<String, dynamic>.from(widget.initialRequestBody);

    requestBody['docId'] = widget.selectedDocId;
    requestBody['collection'] = widget.selectedCollection;
    requestBody['top_k'] = 5;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
      _selectedResultDocId = null;
      _confirmedMatch = null;
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

  // =========================
  // Helpers
  // =========================
  String _generatePin() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  String _oppositeCollection(String collection) {
    return collection == 'lostItems' ? 'foundItems' : 'lostItems';
  }

  String _safeString(dynamic value) {
    return (value ?? '').toString();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getDoc(
      String collection,
      String docId,
      ) {
    return FirebaseFirestore.instance.collection(collection).doc(docId).get();
  }

  // =========================
  // Confirm Match
  // =========================
  Future<void> _confirmMatch(Map<String, dynamic> selected) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Match'),
        content: const Text('هل تريد تأكيد هذه المطابقة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.mainGreen),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);

    try {
      final queryCollection = widget.selectedCollection;
      final matchedCollection = _safeString(selected['collection']).isNotEmpty
          ? _safeString(selected['collection'])
          : _oppositeCollection(queryCollection);

      final queryDocId = widget.selectedDocId;
      final matchedDocId = _safeString(selected['docId']);

      if (matchedDocId.isEmpty) {
        throw Exception('Matched docId is missing');
      }

      late final String foundId;
      late final String lostId;

      if (queryCollection == 'foundItems') {
        foundId = queryDocId;
        lostId = matchedDocId;
      } else {
        foundId = matchedDocId;
        lostId = queryDocId;
      }

      final foundRef =
      FirebaseFirestore.instance.collection('foundItems').doc(foundId);
      final lostRef =
      FirebaseFirestore.instance.collection('lostItems').doc(lostId);

      final batch = FirebaseFirestore.instance.batch();

      batch.update(foundRef, {
        'status': 'has_match',
        'matchedLostItemId': lostId,
        'matchedSimilarity': selected['similarity'],
        'matchedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(lostRef, {
        'status': 'possible_match',
        'matchedFoundItemId': foundId,
        'matchedFoundImagePath': selected['imageUrl'] ?? '',
        'matchedFoundTitle': selected['type'] ?? '',
        'matchedFoundType': selected['type'] ?? '',
        'matchedFoundColor': selected['color'] ?? '',
        'matchedFoundLocation': selected['location'] ?? '',
        'matchedFoundSimilarity': selected['similarity'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final linkRef = FirebaseFirestore.instance.collection('matchLinks').doc();
      batch.set(linkRef, {
        'foundItemId': foundId,
        'lostReportId': lostId,
        'queryCollection': queryCollection,
        'matchedCollection': matchedCollection,
        'similarity': selected['similarity'],
        'status': 'possible_match',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      setState(() {
        _confirmedMatch = {
          ...selected,
          'foundItemId': foundId,
          'lostReportId': lostId,
          'matchLinkId': linkRef.id,
        };
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تأكيد المطابقة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming match: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // =========================
  // Approve for Handover + Generate PIN
  // =========================
  Future<void> _approveForHandover() async {
    final match = _confirmedMatch;
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm a match first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve for Handover'),
        content: const Text(
          'سيتم توليد PIN وتجهيز العنصر للاستلام. هل تريدين المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.mainGreen),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);

    try {
      final foundId = _safeString(match['foundItemId']);
      final lostId = _safeString(match['lostReportId']);

      if (foundId.isEmpty || lostId.isEmpty) {
        throw Exception('Missing foundId or lostId');
      }

      final pin = _generatePin();

      final lostSnap = await _getDoc('lostItems', lostId);
      final lostData = lostSnap.data() ?? {};
      final linkedUserId = _safeString(lostData['userId']);

      final foundRef =
      FirebaseFirestore.instance.collection('foundItems').doc(foundId);
      final lostRef =
      FirebaseFirestore.instance.collection('lostItems').doc(lostId);

      final batch = FirebaseFirestore.instance.batch();

      batch.update(foundRef, {
        'status': 'ready_to_handover',
        'linkedLostReportId': lostId,
        'linkedUserId': linkedUserId,
        'handoverPin': pin,
        'pinGeneratedAt': FieldValue.serverTimestamp(),
        'handoverStatus': 'pending',
        'isPinUsed': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(lostRef, {
        'status': 'ready_to_handover',
        'matchedFoundItemId': foundId,
        'handoverPin': pin,
        'handoverStatus': 'pending',
        'isPinUsed': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final logRef =
      FirebaseFirestore.instance.collection('handoverLogs').doc();

      batch.set(logRef, {
        'foundItemId': foundId,
        'lostReportId': lostId,
        'userId': linkedUserId,
        'action': 'pin_generated',
        'status': 'ready_to_handover',
        'pinGenerated': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('PIN Generated'),
          content: Text(
            'The item is ready for handover.\n\nPIN: $pin',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: widget.mainGreen),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تجهيز العنصر للاستلام وتوليد PIN'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving handover: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // =========================
  // Optional PIN Verification Helper
  // تستخدم لاحقًا في HandoverPinScreen
  // =========================
  Future<bool> verifyHandoverPin({
    required String foundItemId,
    required String enteredPin,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('foundItems')
        .doc(foundItemId)
        .get();

    if (!doc.exists) return false;

    final data = doc.data() ?? {};
    final storedPin = _safeString(data['handoverPin']);
    final status = _safeString(data['status']);
    final isPinUsed = data['isPinUsed'] == true;

    return status == 'ready_to_handover' &&
        !isPinUsed &&
        storedPin == enteredPin.trim();
  }

  // =========================
  // UI
  // =========================
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
            width: 90,
            child: Text(
              '$label:',
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
        ],
      ),
    );
  }

  Future<void> _showResultDetails(Map<String, dynamic> result) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        final image = _safeString(result['imageUrl']);
        final matchedDocId = _safeString(result['docId']);
        final similarity =
        (((result['similarity'] ?? 0) as num).toDouble() * 100)
            .toStringAsFixed(2);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 650),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Match Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
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
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
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
                            _detailRow('ID', matchedDocId),
                            _detailRow('Similarity', '$similarity%'),
                            _detailRow('Collection', _safeString(result['collection'])),
                            _detailRow('Type', _safeString(result['type'])),
                            _detailRow('Color', _safeString(result['color'])),
                            _detailRow('Location', _safeString(result['location'])),
                            _detailRow('Status', _safeString(result['status'])),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isActionLoading
                          ? null
                          : () async {
                        Navigator.pop(context);
                        await _confirmMatch(result);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.mainGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Confirm This Match'),
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
    final docId = _safeString(item['docId']);
    final image = _safeString(item['imageUrl']);
    final similarity = ((item['similarity'] ?? 0) as num).toDouble();
    final isBest = index == 0;
    final isSelected = _selectedResultDocId == docId;

    return InkWell(
      onTap: () {
        setState(() => _selectedResultDocId = docId);
      },
      onLongPress: () => _showResultDetails(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isBest ? const Color(0xFFEFF8F0) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? widget.mainGreen
                : (isBest ? Colors.green.shade400 : Colors.transparent),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('Collection: ${_safeString(item['collection'])}'),
                  Text('Type: ${_safeString(item['type'])}'),
                  Text(
                    'Similarity: ${(similarity * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (isBest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                IconButton(
                  onPressed: () => _showResultDetails(item),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmedMatchSection() {
    if (_confirmedMatch == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirmed Match',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('Found ID: ${_safeString(_confirmedMatch!['foundItemId'])}'),
          Text('Lost ID: ${_safeString(_confirmedMatch!['lostReportId'])}'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isActionLoading ? null : _approveForHandover,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.mainGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.pin),
              label: const Text('Approve for Handover & Generate PIN'),
            ),
          ),
        ],
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
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Summary',
                  style: TextStyle(
                    color: widget.mainGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Query Doc ID: ${widget.selectedDocId}'),
                Text('Query Collection: ${widget.selectedCollection}'),
                Text('Results: ${_results.length}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildConfirmedMatchSection(),
          if (_confirmedMatch != null) const SizedBox(height: 12),
          if (_results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('No matching results returned'),
              ),
            )
          else
            ListView.separated(
              itemCount: _results.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildResultCard(_results[index], index);
              },
            ),
        ],
      ),
    );
  }
}