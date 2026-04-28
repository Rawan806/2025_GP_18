import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final Color mainGreen = const Color(0xFF243E36);
  final Color beigeColor = const Color(0xFFC3BFB0);

  static const int _pageSize = 15;
  static const int _fetchBatchSize = 20;

  bool _isFetchingReports = false;
  bool _filtersExpanded = true;
  String? _errorMessage;
  Map<String, dynamic>? _searchResponse;
  String? _selectedReportKey;
  String? _selectedResultDocId;

  ReportViewMode _reportViewMode = ReportViewMode.list;
  ResultViewMode _resultViewMode = ResultViewMode.list;
  TimeRangeFilter _timeRangeFilter = TimeRangeFilter.all;

  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedCategory = 'all';
  String _selectedItemType = 'all';
  String _selectedStatus = 'all';

  int _reportPage = 1;
  int _resultPage = 1;

  DocumentSnapshot? _lastLostDoc;
  DocumentSnapshot? _lastFoundDoc;
  bool _hasMoreLost = true;
  bool _hasMoreFound = true;
  bool _hasMoreReports = true;

  List<Map<String, dynamic>> _cachedReports = [];

  final String baseUrl = 'http://10.0.2.2:8001';

  @override
  void initState() {
    super.initState();
    _refreshReports();
  }

  String _collectionPathForType(String type) {
    return type == 'lost' ? 'lostItems' : 'foundItems';
  }

  String _dateFieldForType(String type) {
    return type == 'lost' ? 'lostDate' : 'foundAt';
  }

  List<String> _selectedCollections() {
    if (_selectedItemType == 'lost') return ['lost'];
    if (_selectedItemType == 'found') return ['found'];
    return ['lost', 'found'];
  }

  List<String>? _statusQueryValues() {
    switch (_selectedStatus) {
      case 'submitted':
        return ['submitted'];
      case 'stored':
        return ['stored', 'Stored', 'مخزن'];
      case 'possible_match':
        return ['possible_match'];
      case 'waiting_for_staff_review':
        return ['waiting_for_staff_review'];
      case 'ready_to_handover':
        return ['ready_to_handover'];
      case 'completed':
        return ['completed'];
      case 'cancelled':
        return ['cancelled'];
      case 'under_review':
        return ['Under Review', 'قيد المراجعة'];
      case 'preliminary_match':
        return ['Preliminary Match', 'مطابقة مبدئية'];
      case 'ready_for_pickup':
        return ['Ready for Pickup', 'جاهز للاستلام'];
      case 'closed':
        return ['Closed', 'مغلق'];
      default:
        return null;
    }
  }

  Query _buildCollectionQuery(String type) {
    Query query = FirebaseFirestore.instance.collection(
      _collectionPathForType(type),
    );

    final statuses = _statusQueryValues();
    if (statuses != null) {
      query = query.where('status', whereIn: statuses);
    }

    final dateField = _dateFieldForType(type);

    if (_fromDate != null) {
      query = query.where(
        dateField,
        isGreaterThanOrEqualTo: Timestamp.fromDate(_fromDate!),
      );
    }

    if (_toDate != null) {
      final endOfDay = DateTime(
        _toDate!.year,
        _toDate!.month,
        _toDate!.day,
        23,
        59,
        59,
      );
      query = query.where(
        dateField,
        isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
      );
    }

    query = query.orderBy(dateField, descending: true);

    final lastDoc = type == 'lost' ? _lastLostDoc : _lastFoundDoc;
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.limit(_fetchBatchSize);
  }

  Future<void> _refreshReports() async {
    setState(() {
      _cachedReports = [];
      _reportPage = 1;
      _lastLostDoc = null;
      _lastFoundDoc = null;
      _hasMoreLost = true;
      _hasMoreFound = true;
      _hasMoreReports = true;
      _selectedReportKey = null;
      _errorMessage = null;
    });

    await _fetchNextReportsBatch(forceRefresh: true);

    if (_needsExpandedFetch()) {
      while (_hasMoreReports &&
          _filterReports(_cachedReports).length < _pageSize) {
        await _fetchNextReportsBatch();
      }
    }
  }

  bool _needsExpandedFetch() {
    return _selectedCategory != 'all';
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  Future<void> _fetchNextReportsBatch({bool forceRefresh = false}) async {
    if (_isFetchingReports) return;

    final collections = _selectedCollections();
    final shouldFetchLost = collections.contains('lost') && _hasMoreLost;
    final shouldFetchFound = collections.contains('found') && _hasMoreFound;

    if (!forceRefresh && !shouldFetchLost && !shouldFetchFound) {
      setState(() {
        _hasMoreReports = false;
      });
      return;
    }

    setState(() {
      _isFetchingReports = true;
      _errorMessage = null;
    });

    try {
      final newReports = <Map<String, dynamic>>[];

      if (shouldFetchLost) {
        final snapshot = await _buildCollectionQuery('lost').get();

        if (snapshot.docs.isNotEmpty) {
          _lastLostDoc = snapshot.docs.last;
          newReports.addAll(
            snapshot.docs.map((doc) => _mapReportDoc(doc, 'lost')),
          );
        }

        if (snapshot.docs.length < _fetchBatchSize) {
          _hasMoreLost = false;
        }
      }

      if (shouldFetchFound) {
        final snapshot = await _buildCollectionQuery('found').get();

        if (snapshot.docs.isNotEmpty) {
          _lastFoundDoc = snapshot.docs.last;
          newReports.addAll(
            snapshot.docs.map((doc) => _mapReportDoc(doc, 'found')),
          );
        }

        if (snapshot.docs.length < _fetchBatchSize) {
          _hasMoreFound = false;
        }
      }

      final merged = [..._cachedReports, ...newReports];

      final deduped = <String, Map<String, dynamic>>{
        for (final report in merged) (report['_key'] ?? '').toString(): report,
      }.values.toList();

      deduped.sort((a, b) {
        final da = _extractReportDate(a) ?? DateTime(1970);
        final db = _extractReportDate(b) ?? DateTime(1970);
        return db.compareTo(da);
      });

      setState(() {
        _cachedReports = deduped;
        _hasMoreReports =
            (_selectedCollections().contains('lost') && _hasMoreLost) ||
                (_selectedCollections().contains('found') && _hasMoreFound);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading reports: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingReports = false;
        });
      }
    }
  }

  Map<String, dynamic> _mapReportDoc(DocumentSnapshot doc, String collection) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return {
      '_key': '$collection:${doc.id}',
      'firebaseDocId': doc.id,
      'collection': collection,
      'apiCollection': _collectionPathForType(collection),
      'id': (data['id'] ?? doc.id).toString(),
      'docId': (data['docId'] ?? doc.id).toString(),
      'doc_num': (data['doc_num'] ?? '').toString(),
      'title': (data['title'] ?? '').toString(),
      'type': (data['type'] ?? '').toString(),
      'category': (data['category'] ?? data['type'] ?? '').toString(),
      'status': (data['status'] ?? '').toString(),
      'itemCategory': (data['itemCategory'] ?? collection).toString(),
      'description': (data['description'] ?? '').toString(),
      'imagePath': (data['imagePath'] ?? data['imageUrl'] ?? '').toString(),
      'imageUrl': (data['imageUrl'] ?? data['imagePath'] ?? '').toString(),
      'date': (data['date'] ?? '').toString(),
      'createdAt': data['createdAt'],
      'lostDate': data['lostDate'],
      'foundAt': data['foundAt'],
      'color': (data['color'] ?? '').toString(),
      'location': (data['reportLocation'] ?? data['foundLocation'] ?? '')
          .toString(),
      'userId': (data['userId'] ?? '').toString(),
    };
  }

  DateTime? _extractReportDate(Map<String, dynamic> report) {
    final lostDate = report['lostDate'];
    if (lostDate is Timestamp) return lostDate.toDate();

    final foundAt = report['foundAt'];
    if (foundAt is Timestamp) return foundAt.toDate();

    final createdAt = report['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();

    if (createdAt is String) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) return parsed;
    }

    final date = report['date'];
    if (date is String) {
      return DateTime.tryParse(date);
    }

    return null;
  }

  bool _matchesDateFilters(Map<String, dynamic> report) {
    final reportDate = _extractReportDate(report);

    if (_fromDate != null &&
        (reportDate == null || reportDate.isBefore(_fromDate!))) {
      return false;
    }

    if (_toDate != null && reportDate != null) {
      final endOfDay = DateTime(
        _toDate!.year,
        _toDate!.month,
        _toDate!.day,
        23,
        59,
        59,
      );

      if (reportDate.isAfter(endOfDay)) return false;
    }

    if (_timeRangeFilter == TimeRangeFilter.all || reportDate == null) {
      return true;
    }

    final now = DateTime.now();
    late final DateTime threshold;

    switch (_timeRangeFilter) {
      case TimeRangeFilter.last7Days:
        threshold = now.subtract(const Duration(days: 7));
        break;
      case TimeRangeFilter.last30Days:
        threshold = now.subtract(const Duration(days: 30));
        break;
      case TimeRangeFilter.last90Days:
        threshold = now.subtract(const Duration(days: 90));
        break;
      case TimeRangeFilter.all:
        threshold = DateTime(1970);
        break;
    }

    return !reportDate.isBefore(threshold);
  }

  bool _matchesStatusFilter(String status) {
    if (_selectedStatus == 'all') return true;

    final normalized = status.toLowerCase();

    if (_selectedStatus == 'submitted') return normalized == 'submitted';
    if (_selectedStatus == 'stored') {
      return normalized == 'stored' || status.contains('مخزن');
    }
    if (_selectedStatus == 'possible_match') {
      return normalized == 'possible_match';
    }
    if (_selectedStatus == 'waiting_for_staff_review') {
      return normalized == 'waiting_for_staff_review';
    }
    if (_selectedStatus == 'ready_to_handover') {
      return normalized == 'ready_to_handover';
    }
    if (_selectedStatus == 'completed') return normalized == 'completed';
    if (_selectedStatus == 'cancelled') return normalized == 'cancelled';

    if (_selectedStatus == 'under_review') {
      return normalized.contains('under review') ||
          normalized.contains('قيد المراجعة');
    }

    if (_selectedStatus == 'preliminary_match') {
      return normalized.contains('preliminary match') ||
          normalized.contains('مطابقة مبدئية');
    }

    if (_selectedStatus == 'ready_for_pickup') {
      return normalized.contains('ready for pickup') ||
          normalized.contains('جاهز للاستلام');
    }

    if (_selectedStatus == 'closed') {
      return normalized.contains('closed') || normalized.contains('مغلق');
    }

    return true;
  }

  List<Map<String, dynamic>> _filterReports(
      List<Map<String, dynamic>> reports,
      ) {
    final selectedCategory = _normalize(_selectedCategory);

    return reports.where((report) {
      final category = _normalize((report['category'] ?? '').toString());
      final type = _normalize((report['type'] ?? '').toString());
      final status = (report['status'] ?? '').toString();

      final matchesCategory = selectedCategory == 'all' ||
          category == selectedCategory ||
          type == selectedCategory;

      return matchesCategory &&
          _matchesStatusFilter(status) &&
          _matchesDateFilters(report);
    }).toList();
  }

  List<String> _buildCategoryOptions(List<Map<String, dynamic>> reports) {
    final seen = <String>{};
    final categories = <String>[];

    for (final report in reports) {
      final rawCategory = (report['category'] ?? '').toString().trim();
      if (rawCategory.isEmpty || rawCategory == 'null') continue;

      final normalized = rawCategory.toLowerCase();
      if (seen.add(normalized)) {
        categories.add(rawCategory);
      }
    }

    categories.sort();
    return categories;
  }

  String _reportDisplayId(Map<String, dynamic> report) {
    final docNum = (report['doc_num'] ?? '').toString();
    if (docNum.isNotEmpty && docNum != 'null') return docNum;

    final docId = (report['docId'] ?? '').toString();
    if (docId.isNotEmpty && docId != 'null') return docId;

    return (report['id'] ?? '').toString();
  }

  String _resolveSearchDocId(Map<String, dynamic> report) {
    final firebaseDocId = (report['firebaseDocId'] ?? '').toString();
    if (firebaseDocId.isNotEmpty && firebaseDocId != 'null') {
      return firebaseDocId;
    }

    final docId = (report['docId'] ?? '').toString();
    if (docId.isNotEmpty && docId != 'null') return docId;

    final docNum = (report['doc_num'] ?? '').toString();
    if (docNum.isNotEmpty && docNum != 'null') return docNum;

    return (report['id'] ?? '').toString();
  }

  String _resolveApiCollection(Map<String, dynamic> report) {
    final apiCollection = (report['apiCollection'] ?? '').toString();
    if (apiCollection == 'lostItems' || apiCollection == 'foundItems') {
      return apiCollection;
    }

    final collection = (report['collection'] ?? '').toString();
    if (collection == 'lost') return 'lostItems';
    if (collection == 'found') return 'foundItems';

    return 'foundItems';
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'submitted') return Colors.orange;
    if (normalized == 'stored') return Colors.blueGrey;
    if (normalized == 'possible_match') return Colors.blue;
    if (normalized == 'waiting_for_staff_review') return Colors.deepPurple;
    if (normalized == 'ready_to_handover') return Colors.green;
    if (normalized == 'completed') return Colors.grey;
    if (normalized == 'cancelled') return Colors.redAccent;

    if (status.contains('قيد المراجعة') || status.contains('Under Review')) {
      return Colors.orange;
    }
    if (status.contains('مطابقة مبدئية') ||
        status.contains('Preliminary Match')) {
      return Colors.blue;
    }
    if (status.contains('جاهز للاستلام') ||
        status.contains('Ready for Pickup')) {
      return Colors.green;
    }
    if (status.contains('مغلق') || status.contains('Closed')) {
      return Colors.grey;
    }

    return Colors.black87;
  }

  Future<void> _pickDate({required bool isFromDate}) async {
    final now = DateTime.now();
    final initial = isFromDate ? (_fromDate ?? now) : (_toDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );

    if (picked == null) return;

    setState(() {
      if (isFromDate) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
      _reportPage = 1;
    });

    await _refreshReports();
  }

  Map<String, dynamic> _buildSearchRequestBody({
    required String docId,
    required String collection,
  }) {
    return {
      'docId': docId,
      'collection': collection,
      'top_k': 5,
      'page_size': _pageSize,
      'client_filters': {
        'text': '',
        'date_from': _fromDate?.toIso8601String(),
        'date_to': _toDate?.toIso8601String(),
        'time_range': _timeRangeFilter.name,
        'category': _selectedCategory,
        'item_type': _selectedItemType,
        'status': _selectedStatus,
      },
    };
  }

  Future<void> _openMatchResultsPage(Map<String, dynamic> report) async {
    final docId = _resolveSearchDocId(report);
    final collection = _resolveApiCollection(report);

    final body = _buildSearchRequestBody(
      docId: docId,
      collection: collection,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchResultsPage(
          selectedDocId: docId,
          selectedCollection: collection,
          baseUrl: baseUrl,
          initialRequestBody: body,
          mainGreen: mainGreen,
        ),
      ),
    );
  }

  Future<void> _searchForMatches() async {
    if (_selectedReportKey == null) {
      setState(() {
        _errorMessage = 'Please select a report first';
      });
      return;
    }

    final selectedReport = _cachedReports.firstWhere(
          (r) => r['_key'] == _selectedReportKey,
      orElse: () => {},
    );

    if (selectedReport.isEmpty) {
      setState(() {
        _errorMessage = 'Selected report no longer available';
      });
      return;
    }

    await _openMatchResultsPage(selectedReport);
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

  Future<void> _showReportDetails(Map<String, dynamic> report) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        final image = (report['imagePath'] ?? report['imageUrl'] ?? '').toString();

        return Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Center(
                  child: SizedBox(width: 38, child: Divider(thickness: 4)),
                ),
                const SizedBox(height: 10),
                Text(
                  'Report Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: mainGreen,
                  ),
                ),
                const SizedBox(height: 12),
                if (image.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      image,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image, size: 44),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _detailRow('ID', _reportDisplayId(report)),
                _detailRow('Collection', _resolveApiCollection(report)),
                _detailRow('Type', (report['itemCategory'] ?? '').toString()),
                _detailRow('Category', (report['category'] ?? '').toString()),
                _detailRow('Status', (report['status'] ?? '').toString()),
                _detailRow('Date', (report['date'] ?? '').toString()),
                _detailRow(
                  'Description',
                  (report['description'] ?? '').toString(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedReportKey = report['_key']?.toString();
                      });
                      Navigator.pop(context);
                      _openMatchResultsPage(report);
                    },
                    icon: const Icon(Icons.travel_explore),
                    label: const Text('Find Match'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showResultDetails(Map<String, dynamic> result) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        final image = (result['imageUrl'] ?? '').toString();

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
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                _detailRow('ID', (result['docId'] ?? '').toString()),
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
          ],
        );
      },
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

  Future<void> confirmMatch() async {
    if (_selectedResultDocId == null || _searchResponse == null) return;

    final results = (_searchResponse!['results'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    final selected = results.firstWhere(
          (r) => (r['docId'] ?? '').toString() == _selectedResultDocId,
      orElse: () => {},
    );

    if (selected.isEmpty) return;

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
            style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    final notify = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notification Step (UI Only)'),
        content: const Text('هل تريد إرسال إشعار للمُبلِّغ بوجود تطابق محتمل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notify == true
              ? 'تم تسجيل Potential Match + خطوة إشعار (UI)'
              : 'تم تسجيل Potential Match',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _filterReports(_cachedReports);

    final pagedReports = filteredReports
        .skip((_reportPage - 1) * _pageSize)
        .take(_pageSize)
        .toList();

    final selectedReport = filteredReports.firstWhere(
          (r) => r['_key'] == _selectedReportKey,
      orElse: () => {},
    );

    final categories = _buildCategoryOptions(_cachedReports);
    final categoriesForDropdown = <String>[...categories];

    if (_selectedCategory != 'all' &&
        !categoriesForDropdown.contains(_selectedCategory)) {
      categoriesForDropdown.insert(0, _selectedCategory);
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: beigeColor,
        appBar: AppBar(
          backgroundColor: mainGreen,
          centerTitle: true,
          title: const Text(
            'Employee Match Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isFetchingReports && _cachedReports.isEmpty
            ? Center(child: CircularProgressIndicator(color: mainGreen))
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilterSection(
              categoriesForDropdown,
              _selectedCategory,
            ),
            const SizedBox(height: 14),
            _buildReportHeader(filteredReports.length),
            const SizedBox(height: 8),
            _buildReportsView(pagedReports),
            const SizedBox(height: 10),
            _buildReportPagination(filteredReports.length),
            if (selectedReport.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Selected Report: ${_reportDisplayId(selectedReport)}',
                style: TextStyle(
                  color: mainGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _searchForMatches,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.search),
                label: const Text('Find Match for Selected Report'),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
      List<String> categories,
      String validSelectedCategory,
      ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _filtersExpanded = !_filtersExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filters',
                    style: TextStyle(
                      color: mainGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  _filtersExpanded ? Icons.expand_less : Icons.expand_more,
                  color: mainGreen,
                ),
              ],
            ),
          ),
          if (_filtersExpanded) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedItemType,
                    decoration: _dropdownDecoration('Type'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Types')),
                      DropdownMenuItem(value: 'lost', child: Text('Lost')),
                      DropdownMenuItem(value: 'found', child: Text('Found')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _selectedItemType = v;
                        _reportPage = 1;
                      });
                      _refreshReports();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedStatus,
                    decoration: _dropdownDecoration('Status'),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Statuses'),
                      ),
                      DropdownMenuItem(
                        value: 'submitted',
                        child: Text('Submitted'),
                      ),
                      DropdownMenuItem(
                        value: 'stored',
                        child: Text('Stored'),
                      ),
                      DropdownMenuItem(
                        value: 'possible_match',
                        child: Text('Possible Match'),
                      ),
                      DropdownMenuItem(
                        value: 'waiting_for_staff_review',
                        child: Text('Waiting Review'),
                      ),
                      DropdownMenuItem(
                        value: 'ready_to_handover',
                        child: Text('Ready Handover'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _selectedStatus = v;
                        _reportPage = 1;
                      });
                      _refreshReports();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: validSelectedCategory,
                    decoration: _dropdownDecoration('Category'),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('All Categories'),
                      ),
                      ...categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _selectedCategory = v;
                        _reportPage = 1;
                      });
                      _refreshReports();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<TimeRangeFilter>(
                    isExpanded: true,
                    value: _timeRangeFilter,
                    decoration: _dropdownDecoration('Time Range'),
                    items: const [
                      DropdownMenuItem(
                        value: TimeRangeFilter.all,
                        child: Text('All Time'),
                      ),
                      DropdownMenuItem(
                        value: TimeRangeFilter.last7Days,
                        child: Text('Last 7 days'),
                      ),
                      DropdownMenuItem(
                        value: TimeRangeFilter.last30Days,
                        child: Text('Last 30 days'),
                      ),
                      DropdownMenuItem(
                        value: TimeRangeFilter.last90Days,
                        child: Text('Last 90 days'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _timeRangeFilter = v;
                        _reportPage = 1;
                      });
                      _refreshReports();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isFromDate: true),
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _fromDate == null
                          ? 'From Date'
                          : '${_fromDate!.year}-${_fromDate!.month}-${_fromDate!.day}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isFromDate: false),
                    icon: const Icon(Icons.event),
                    label: Text(
                      _toDate == null
                          ? 'To Date'
                          : '${_toDate!.year}-${_toDate!.month}-${_toDate!.day}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                        _timeRangeFilter = TimeRangeFilter.all;
                        _selectedCategory = 'all';
                        _selectedItemType = 'all';
                        _selectedStatus = 'all';
                        _reportPage = 1;
                      });
                      _refreshReports();
                    },
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF4F4F1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildReportHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Reports ($count)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: mainGreen,
            fontSize: 16,
          ),
        ),
        SegmentedButton<ReportViewMode>(
          segments: const [
            ButtonSegment(
              value: ReportViewMode.list,
              icon: Icon(Icons.view_list),
              label: Text('List'),
            ),
            ButtonSegment(
              value: ReportViewMode.grid,
              icon: Icon(Icons.grid_view),
              label: Text('Grid'),
            ),
          ],
          selected: {_reportViewMode},
          onSelectionChanged: (selection) {
            setState(() {
              _reportViewMode = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildReportsView(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No reports found with current filters')),
      );
    }

    if (_reportViewMode == ReportViewMode.grid) {
      return GridView.builder(
        itemCount: reports.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildReportCard(report, isGrid: true);
        },
      );
    }

    return ListView.separated(
      itemCount: reports.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildReportCard(report, isGrid: false);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, {required bool isGrid}) {
    final key = (report['_key'] ?? '').toString();
    final isSelected = _selectedReportKey == key;
    final image = (report['imagePath'] ?? report['imageUrl'] ?? '').toString();
    final status = (report['status'] ?? '').toString();

    return InkWell(
      onTap: () {
        setState(() {
          _selectedReportKey = key;
        });
      },
      onLongPress: () => _showReportDetails(report),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? mainGreen : Colors.transparent,
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
        child: isGrid
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: image.isNotEmpty
                          ? Image.network(
                        image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imagePlaceholder(),
                      )
                          : _imagePlaceholder(),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.white.withOpacity(0.9),
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showReportDetails(report),
                        icon: const Icon(Icons.info_outline, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _reportDisplayId(report),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: mainGreen,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              (report['title'] ?? '').toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              status,
              style: TextStyle(color: _statusColor(status), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        )
            : Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: image.isNotEmpty
                    ? Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _imagePlaceholder(),
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
                    _reportDisplayId(report),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: mainGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    (report['title'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    (report['itemCategory'] ?? '')
                        .toString()
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                IconButton(
                  onPressed: () => _showReportDetails(report),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(child: Icon(Icons.image_not_supported)),
    );
  }

  Widget _buildReportPagination(int filteredCount) {
    final hasPrev = _reportPage > 1;
    final hasLoadedNext = filteredCount > (_reportPage * _pageSize);
    final hasNext = hasLoadedNext || _hasMoreReports;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: hasPrev
              ? () {
            setState(() {
              _reportPage -= 1;
            });
          }
              : null,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Previous'),
        ),
        Text('Page $_reportPage'),
        OutlinedButton.icon(
          onPressed: hasNext
              ? () async {
            if (!hasLoadedNext && _hasMoreReports) {
              await _fetchNextReportsBatch();
            }

            final updatedCount = _filterReports(_cachedReports).length;

            if (updatedCount > (_reportPage * _pageSize) ||
                _hasMoreReports) {
              setState(() {
                _reportPage += 1;
              });
            }
          }
              : null,
          icon: const Icon(Icons.chevron_right),
          label: const Text('Next'),
        ),
      ],
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
  static const int _pageSize = 15;

  ResultViewMode _resultViewMode = ResultViewMode.list;
  String? _selectedResultDocId;
  int _resultPage = 1;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _searchResponse;

  @override
  void initState() {
    super.initState();
    _fetchMatchesForReport();
  }

  Future<void> _fetchMatchesForReport() async {
    final requestBody = Map<String, dynamic>.from(widget.initialRequestBody);
    requestBody['docId'] = widget.selectedDocId;
    requestBody['collection'] = widget.selectedCollection;
    requestBody['top_k'] = 5;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResponse = null;
      _selectedResultDocId = null;
      _resultPage = 1;
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'docId': widget.selectedDocId,
          'collection': widget.selectedCollection,
          'top_k': 5,
        }),
      );

      if (response.statusCode >= 400) {
        throw Exception(
          'Server error ${response.statusCode}: ${response.body}',
        );
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

      data['results'] = rawResults;
      data['request_body_preview'] = requestBody;

      setState(() {
        _searchResponse = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getMatchColor(String label) {
    switch (label) {
      case 'strong_match':
        return Colors.green;
      case 'potential_match':
        return Colors.orange;
      default:
        return Colors.red;
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
                      width: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                _detailRow('ID', (result['docId'] ?? '').toString()),
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
          ],
        );
      },
    );
  }

  Future<void> _confirmMatch() async {
    if (_selectedResultDocId == null) return;

    final results = (_searchResponse?['results'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final selected = results.firstWhere(
          (r) => (r['docId'] ?? '').toString() == _selectedResultDocId,
      orElse: () => {},
    );

    if (selected.isEmpty) return;

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
    if (!mounted) return;

    final notify = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notification Step (UI Only)'),
        content: const Text('هل تريد إرسال إشعار للمُبلِّغ بوجود تطابق محتمل؟'),
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

    if (!mounted) return;

    try {
      final queryCollection = widget.selectedCollection;
      final matchedCollection = (selected['collection'] ?? '').toString();
      final matchedDocId = (selected['docId'] ?? '').toString();

      final queryRef = FirebaseFirestore.instance
          .collection(queryCollection)
          .doc(widget.selectedDocId);

      final matchedRef = FirebaseFirestore.instance
          .collection(matchedCollection)
          .doc(matchedDocId);

      if (queryCollection == 'lostItems') {
        await queryRef.update({
          'status': 'possible_match',
          'matchedFoundItemId': matchedDocId,
          'matchedFoundImagePath': selected['imageUrl'] ?? '',
          'matchedFoundTitle': selected['type'] ?? '',
          'matchedFoundType': selected['type'] ?? '',
          'matchedFoundColor': selected['color'] ?? '',
          'matchedFoundLocation': selected['location'] ?? '',
          'matchedFoundSimilarity': selected['similarity'],
          'notified': notify == true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await matchedRef.update({
          'status': 'has_match',
          'matchedLostItemId': widget.selectedDocId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await matchedRef.update({
          'status': 'possible_match',
          'matchedFoundItemId': widget.selectedDocId,
          'matchedFoundImagePath': selected['imageUrl'] ?? '',
          'matchedFoundTitle': selected['type'] ?? '',
          'matchedFoundType': selected['type'] ?? '',
          'matchedFoundColor': selected['color'] ?? '',
          'matchedFoundLocation': selected['location'] ?? '',
          'matchedFoundSimilarity': selected['similarity'],
          'notified': notify == true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await queryRef.update({
          'status': 'has_match',
          'matchedLostItemId': matchedDocId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notify == true
                ? 'تم تسجيل Potential Match + خطوة إشعار (UI)'
                : 'تم تسجيل Potential Match',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error: $e'),
        ),
      );
    }
  }

  String _formatScore(dynamic value) {
    if (value is num) return value.toStringAsFixed(3);
    return '-';
  }

  Widget _buildResultSummary() {
    final topScore = _searchResponse?['top_score'];
    final avgScore = _searchResponse?['avg_top5_score'];
    final latency = _searchResponse?['search_time_ms'];

    return Container(
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
          Text('Top Score: ${_formatScore(topScore)}'),
          Text('Avg Top-K: ${_formatScore(avgScore)}'),
          Text('Latency: ${latency ?? '-'} ms'),
          Text('Searched In: ${_searchResponse?['searched_in'] ?? '-'}'),
        ],
      ),
    );
  }

  Widget _buildResultHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Potential Matches ($count)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.mainGreen,
            fontSize: 16,
          ),
        ),
        SegmentedButton<ResultViewMode>(
          segments: const [
            ButtonSegment(
              value: ResultViewMode.list,
              icon: Icon(Icons.view_list),
              label: Text('List'),
            ),
            ButtonSegment(
              value: ResultViewMode.grid,
              icon: Icon(Icons.grid_view),
              label: Text('Grid'),
            ),
          ],
          selected: {_resultViewMode},
          onSelectionChanged: (selection) {
            setState(() {
              _resultViewMode = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildResultCard(
      Map<String, dynamic> item,
      int index, {
        required bool isGrid,
      }) {
    final label = (item['match_label'] ?? 'weak_match').toString();
    final docId = (item['docId'] ?? '').toString();
    final image = (item['imageUrl'] ?? '').toString();
    final similarity = ((item['similarity'] ?? 0) as num).toDouble();
    final isSelected = _selectedResultDocId == docId;
    final isBest = index == 0;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedResultDocId = docId;
        });
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
        child: Stack(
          children: [
            isGrid
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: image.isNotEmpty
                              ? Image.network(
                            image,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _imagePlaceholder(),
                          )
                              : _imagePlaceholder(),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.white.withOpacity(0.9),
                          shape: const CircleBorder(),
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _showResultDetails(item),
                            icon: const Icon(
                              Icons.info_outline,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  docId,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.mainGreen,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('Type: ${(item['collection'] ?? '').toString()}'),
                Text(
                  'Date: ${(item['date'] ?? '-').toString()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Similarity: ${(similarity * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            )
                : Row(
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
                      errorBuilder: (_, __, ___) =>
                          _imagePlaceholder(),
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
                      Text(
                        'Type: ${(item['collection'] ?? '').toString()}',
                      ),
                      Text('Date: ${(item['date'] ?? '-').toString()}'),
                      Text(
                        'Similarity: ${(similarity * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      Icons.circle,
                      color: _getMatchColor(label),
                      size: 14,
                    ),
                    IconButton(
                      onPressed: () => _showResultDetails(item),
                      icon: const Icon(Icons.info_outline),
                    ),
                  ],
                ),
              ],
            ),
            if (isBest)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Best Match',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('No matching results returned')),
      );
    }

    if (_resultViewMode == ResultViewMode.grid) {
      return GridView.builder(
        itemCount: results.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          final item = results[index];
          final actualIndex = ((_resultPage - 1) * _pageSize) + index;
          return _buildResultCard(item, actualIndex, isGrid: true);
        },
      );
    }

    return ListView.separated(
      itemCount: results.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = results[index];
        final actualIndex = ((_resultPage - 1) * _pageSize) + index;
        return _buildResultCard(item, actualIndex, isGrid: false);
      },
    );
  }

  Widget _buildResultPagination(int totalResults) {
    if (totalResults <= _pageSize) {
      return const SizedBox.shrink();
    }

    final totalPages = (totalResults / _pageSize).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: _resultPage > 1
              ? () {
            setState(() {
              _resultPage -= 1;
            });
          }
              : null,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Previous'),
        ),
        Text('Page $_resultPage / $totalPages'),
        OutlinedButton.icon(
          onPressed: _resultPage < totalPages
              ? () {
            setState(() {
              _resultPage += 1;
            });
          }
              : null,
          icon: const Icon(Icons.chevron_right),
          label: const Text('Next'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = (_searchResponse?['results'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    final pagedResults = results
        .skip((_resultPage - 1) * _pageSize)
        .take(_pageSize)
        .toList();

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
          _buildResultSummary(),
          const SizedBox(height: 10),
          _buildResultHeader(results.length),
          const SizedBox(height: 8),
          _buildResultsView(pagedResults),
          const SizedBox(height: 10),
          _buildResultPagination(results.length),
          if (_selectedResultDocId != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('Confirm Match'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum ReportViewMode { list, grid }

enum ResultViewMode { list, grid }

enum TimeRangeFilter { all, last7Days, last30Days, last90Days }