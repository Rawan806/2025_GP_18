import 'package:flutter/material.dart';

class MatchReviewScreen extends StatelessWidget {
  final String lostReportId;
  final Map<String, dynamic> lostReportData;

  const MatchReviewScreen({
    super.key,
    required this.lostReportId,
    required this.lostReportData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Match Review")),
      body: const Center(child: Text("Match review will be available soon")),
    );
  }
}
