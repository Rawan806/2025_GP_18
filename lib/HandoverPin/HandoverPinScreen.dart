import 'package:flutter/material.dart';

class HandoverPinScreen extends StatelessWidget {
  final Map<String, dynamic> lostReportData;

  const HandoverPinScreen({
    super.key,
    required this.lostReportData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Handover PIN")),
      body: const Center(
        child: Text("PIN will appear after staff approval"),
      ),
    );
  }
}