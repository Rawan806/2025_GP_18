import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../staff/found_item_page.dart';
import '../search_page.dart';
import '../welcomePage/welcome_screen.dart';
import '../staff/search_reports_page.dart';
import '../staff/report_details_page.dart';
import '../l10n/app_localizations_helper.dart';
import '../main.dart';

class StaffHomePage extends StatefulWidget {
  const StaffHomePage({super.key});

  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  final Color mainGreen = const Color(0xFF243E36);
  final Color borderBrown = const Color(0xFF272525);

  int _selectedTabIndex = 0; // 0: Lost, 1: Found, 2: Processing, 3: Completed
  bool _sortNewestFirst = true;

  StreamSubscription? _lostSub;
  StreamSubscription? _foundSub;

  List<Map<String, dynamic>> _lostItems = [];
  List<Map<String, dynamic>> _foundItems = [];
  bool _isLoading = true;

  // New Filter States
  bool _filtersExpanded = false;
  String _selectedStatusFilter = 'all';
  String _selectedCategoryFilter = 'all';
  String _selectedTimeFilter = 'all';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _listenToData();
  }

  void _listenToData() {
    _lostSub = FirebaseFirestore.instance
        .collection('lostItems')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _lostItems = snapshot.docs.map((d) {
          final data = d.data();
          data['docId'] = d.id;
          data['isLost'] = true;
          return data;
        }).toList();
        _isLoading = false;
      });
    });

    _foundSub = FirebaseFirestore.instance
        .collection('foundItems')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _foundItems = snapshot.docs.map((d) {
          final data = d.data();
          data['docId'] = d.id;
          data['isLost'] = false;
          return data;
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    _lostSub?.cancel();
    _foundSub?.cancel();
    super.dispose();
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.translate('language', currentLocale.languageCode),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇸🇦'),
                title: Text(AppLocalizations.translate('arabic', currentLocale.languageCode)),
                onTap: () {
                  MyApp.of(context).setLocale(const Locale('ar'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸'),
                title: Text(AppLocalizations.translate('english', currentLocale.languageCode)),
                onTap: () {
                  MyApp.of(context).setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filteredReports {
    List<Map<String, dynamic>> combined = [];

    // Filter by Tab (Type)
    if (_selectedTabIndex == 0) {
      combined = _lostItems;
    } else if (_selectedTabIndex == 1) {
      combined = _foundItems;
    } else if (_selectedTabIndex == 2) {
      final processingCondition = (Map<String, dynamic> item) {
        final s = (item['status'] ?? '').toString().toLowerCase();
        return s.contains('sent') ||
            s.contains('أرسل') ||
            s.contains('approv') ||
            s.contains('موافق') ||
            s.contains('ready') ||
            s.contains('جاهز') ||
            s.contains('under review') ||
            s.contains('قيد المراجعة');
      };
      combined.addAll(_lostItems.where(processingCondition));
      combined.addAll(_foundItems.where(processingCondition));
    } else if (_selectedTabIndex == 3) {
      final completedCondition = (Map<String, dynamic> item) {
        final s = (item['status'] ?? '').toString().toLowerCase();
        return s.contains('clos') ||
            s.contains('مغلق') ||
            s.contains('complet') ||
            s.contains('مكتمل') ||
            s.contains('resolv');
      };
      combined.addAll(_lostItems.where(completedCondition));
      combined.addAll(_foundItems.where(completedCondition));
    }

    // Apply Additional Filters
    return combined.where((item) {
      final s = (item['status'] ?? '').toString().toLowerCase();
      final cat = (item['category'] ?? '').toString().toLowerCase();
      final createdAt = item['createdAt'] is Timestamp
          ? (item['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);

      // Exclude cancelled
      if (s.contains('ملغي') || s.contains('cancel')) return false;

      // Status Filter
      if (_selectedStatusFilter != 'all') {
        if (_selectedStatusFilter == 'stored' && !s.contains('stored') && !s.contains('محفوظ')) return false;
        if (_selectedStatusFilter == 'pending' && !s.contains('pending') && !s.contains('wait')) return false;
        if (_selectedStatusFilter == 'processing' && !s.contains('sent') && !s.contains('ready') && !s.contains('review')) return false;
        if (_selectedStatusFilter == 'completed' && !s.contains('clos') && !s.contains('complet')) return false;
      }

      // Category Filter
      if (_selectedCategoryFilter != 'all') {
        if (!cat.contains(_selectedCategoryFilter)) return false;
      }

      // Date Range Filter
      if (_fromDate != null && createdAt.isBefore(_fromDate!)) return false;
      if (_toDate != null) {
        final endOfDay = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        if (createdAt.isAfter(endOfDay)) return false;
      }

      // Time Range Filter (Quick Select)
      if (_selectedTimeFilter != 'all') {
        final now = DateTime.now();
        if (_selectedTimeFilter == '7days' && createdAt.isBefore(now.subtract(const Duration(days: 7)))) return false;
        if (_selectedTimeFilter == '30days' && createdAt.isBefore(now.subtract(const Duration(days: 30)))) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final tA = a['createdAt'] is Timestamp
            ? (a['createdAt'] as Timestamp).toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b['createdAt'] is Timestamp
            ? (b['createdAt'] as Timestamp).toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        return _sortNewestFirst ? tB.compareTo(tA) : tA.compareTo(tB);
      });
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    final reports = _filteredReports;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mainGreen,
          foregroundColor: Colors.white,
          title: Text(
            AppLocalizations.translate('staffHome', currentLocale.languageCode),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => _showLanguageDialog(context),
              icon: const Icon(Icons.language),
              tooltip: AppLocalizations.translate('language', currentLocale.languageCode),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                );
              },
              icon: const Icon(Icons.logout),
              tooltip: AppLocalizations.translate('logout', currentLocale.languageCode),
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(color: Colors.white.withOpacity(0.25)),
            _isLoading
                ? Center(child: CircularProgressIndicator(color: mainGreen))
                : Column(
                    children: [
                      _buildHeaderActions(context),
                      _buildTabsAndFilters(isArabic),
                      Expanded(
                        child: reports.isEmpty
                            ? Center(
                                child: Text(
                                  isArabic ? 'لا توجد بلاغات حالياً' : 'No reports yet',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w600),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: reports.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final report = reports[index];
                                  return _ReportListTile(
                                    report: report,
                                    mainColor: mainGreen,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReportDetailsPage(
                                            report: report,
                                            mainGreen: mainGreen,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FoundItemPage()));
            },
            icon: const Icon(Icons.add_circle_outline),
            label: Text(
              AppLocalizations.translate('reportFoundedItem', currentLocale.languageCode),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _syncTypeWithTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  Widget _buildTabsAndFilters(bool isArabic) {
    final currentLocale = Localizations.localeOf(context);
    return Column(
      children: [
        // Collapsible Filters Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 20, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.translate('filters', currentLocale.languageCode),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  Icon(_filtersExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.black54),
                ],
              ),
            ),
          ),
        ),

        // Expanded Filters Content
        if (_filtersExpanded)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildFilterDropdown('Type', _getTypeString(), _getTypeOptions(), (val) {
                      if (val == 'Lost') _syncTypeWithTab(0);
                      else if (val == 'Found') _syncTypeWithTab(1);
                      else if (val == 'Under Processing') _syncTypeWithTab(2);
                      else if (val == 'Completed') _syncTypeWithTab(3);
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterDropdown('Status', _selectedStatusFilter, ['all', 'stored', 'pending', 'processing', 'completed'], (val) {
                      setState(() => _selectedStatusFilter = val!);
                    })),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildFilterDropdown('Category', _selectedCategoryFilter, ['all', 'electronics', 'jewelry', 'bags', 'documentsCards', 'other'], (val) {
                      setState(() => _selectedCategoryFilter = val!);
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterDropdown('Time', _selectedTimeFilter, ['all', '7days', '30days'], (val) {
                      setState(() => _selectedTimeFilter = val!);
                    })),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isFrom: true),
                        child: Text(_fromDate == null ? AppLocalizations.translate('fromDate', currentLocale.languageCode) : '${_fromDate!.day}/${_fromDate!.month}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isFrom: false),
                        child: Text(_toDate == null ? AppLocalizations.translate('toDate', currentLocale.languageCode) : '${_toDate!.day}/${_toDate!.month}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87),
                    onPressed: _resetFilters,
                    child: Text(AppLocalizations.translate('reset', currentLocale.languageCode)),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTabButton(0, isArabic ? 'مفقود' : 'Lost'),
              _buildTabButton(1, isArabic ? 'معثور عليه' : 'Found'),
              _buildTabButton(2, isArabic ? 'قيد المعالجة' : 'Under Processing'),
              _buildTabButton(3, isArabic ? 'مكتمل' : 'Completed'),
            ],
          ),
        ),

        // Sort Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.sort, size: 16, color: Colors.black54),
              const SizedBox(width: 4),
              DropdownButton<bool>(
                value: _sortNewestFirst,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                items: [
                  DropdownMenuItem(value: true, child: Text(isArabic ? 'الأحدث' : 'Newest', style: const TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: false, child: Text(isArabic ? 'الأقدم' : 'Oldest', style: const TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _sortNewestFirst = val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTypeString() {
    if (_selectedTabIndex == 0) return 'Lost';
    if (_selectedTabIndex == 1) return 'Found';
    if (_selectedTabIndex == 2) return 'Under Processing';
    if (_selectedTabIndex == 3) return 'Completed';
    return 'Lost';
  }

  List<String> _getTypeOptions() {
    return ['Lost', 'Found', 'Under Processing', 'Completed'];
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    final currentLocale = Localizations.localeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.translate(label.toLowerCase(), currentLocale.languageCode), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: options.map((opt) {
                String key = opt;
                if (opt == 'all') {
                  if (label == 'Status') key = 'allStatuses';
                  else if (label == 'Type') key = 'allTypes';
                  else if (label == 'Category') key = 'allCategories';
                  else if (label == 'Time') key = 'allTime';
                }
                return DropdownMenuItem(
                  value: opt,
                  child: Text(AppLocalizations.translate(key, currentLocale.languageCode), style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked;
        else _toDate = picked;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedStatusFilter = 'all';
      _selectedCategoryFilter = 'all';
      _selectedTimeFilter = 'all';
      _fromDate = null;
      _toDate = null;
    });
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? mainGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: mainGreen, width: 1.5),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : mainGreen,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.90),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportListTile extends StatelessWidget {
  final Map<String, dynamic> report;
  final Color mainColor;
  final VoidCallback onTap;

  const _ReportListTile({
    required this.report,
    required this.mainColor,
    required this.onTap,
  });

  String _getLocalizedStatus(String status, String languageCode) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('open') || statusLower.contains('مفتوح')) {
      return AppLocalizations.translate('open', languageCode);
    } else if (statusLower.contains('closed') || statusLower.contains('مغلق')) {
      return AppLocalizations.translate('closed', languageCode);
    } else if (statusLower.contains('pending') || statusLower.contains('قيد الانتظار')) {
      return AppLocalizations.translate('pending', languageCode);
    } else if (status.contains('مطابقة مبدئية') || status.contains('Preliminary Match')) {
      return AppLocalizations.translate('preliminaryMatch', languageCode);
    } else if (status.contains('جاهز للاستلام') || status.contains('Ready for Pickup')) {
      return AppLocalizations.translate('readyForPickup', languageCode);
    } else if (status.contains('قيد المراجعة') || status.contains('Under Review')) {
      return AppLocalizations.translate('underReview', languageCode);
    } else if (status.contains('محفوظ') || status.contains('Stored')) {
      return AppLocalizations.translate('stored', languageCode);
    } else if (status.contains('أرسل الى المستخدم') || status.contains('Sent to User')) {
      return AppLocalizations.translate('sent_to_user', languageCode);
    } else if (status.contains('ملغي') || status.contains('Cancelled')) {
      return AppLocalizations.translate('cancelled', languageCode);
    }
    return status;
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('stored') || s.contains('محفوظ') || s.contains('submit') || s.contains('pending')) {
      return mainColor;
    } else if (s.contains('sent') || s.contains('أرسل')) {
      return Colors.amber.shade700;
    } else if (s.contains('approv') || s.contains('موافق')) {
      return Colors.blue.shade600;
    } else if (s.contains('ready') || s.contains('جاهز')) {
      return Colors.orange.shade600;
    } else if (s.contains('clos') || s.contains('مغلق')) {
      return Colors.grey.shade600;
    }
    return mainColor;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';

    final id = report['doc_num']?.toString() ?? report['docId']?.toString() ?? '';
    final title = report['title']?.toString() ?? report['type']?.toString() ?? '';
    final statusFromDb = report['status']?.toString() ?? '';
    final status = _getLocalizedStatus(statusFromDb, currentLocale.languageCode);
    final date = report['date']?.toString() ?? '';
    final imageUrl = report['imagePath']?.toString() ?? report['imageUrl']?.toString() ?? '';
    final isLost = report['isLost'] == true;

    final statusColor = _getStatusColor(statusFromDb);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 40))
                    : Container(color: Colors.grey.shade200, child: Icon(Icons.image, color: Colors.grey.shade400, size: 40)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '#$id',
                          style: TextStyle(fontSize: 14, color: mainColor, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(date, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          isLost ? (isArabic ? 'مفقود' : 'Lost') : (isArabic ? 'معثور عليه' : 'Found'),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
