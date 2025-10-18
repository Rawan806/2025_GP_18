import 'package:flutter/material.dart';

class PreviousReportsPage extends StatelessWidget {
  const PreviousReportsPage({super.key});

 final Color mainGreen = const Color(0xFF243E36);
 final Color beigeColor = const Color(0xFFC3BFB0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeColor,
      appBar: AppBar(
        backgroundColor: mainGreen, 
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'البلاغات السابقة',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: const Center(
        child: Text(
          'لا توجد بلاغات حالياً',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black38,
          ),
        ),
      ),
    );
  }
}
