import 'package:flutter/material.dart';

class TrackReportScreen extends StatelessWidget {
  const TrackReportScreen({super.key});

  final Color mainGreen = const Color(0xFF243E36); // اللون المعتمد
  final Color beigeColor = const Color(0xFFC3BFB0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeColor,
      appBar: AppBar(
        backgroundColor: mainGreen,
        centerTitle: true,
        title: Text(
          'متابعة بلاغاتي',
          style: const TextStyle(
            color: Colors.white,         //خليته ابيض اوضح
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      body: Column(
        children: [

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  //  البلاغ رقم 1
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رقم البلاغ: 1023',
                          style: TextStyle(
                            fontSize: 16,
                            color: mainGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('المفقود: هاتف سامسونج أسود'),
                        const SizedBox(height: 6),
                        const Text('الحالة: قيد المراجعة'),
                      ],
                    ),
                  ),

                  //   البلاغ رقم 2
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('رقم البلاغ: 1024', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('المفقود: بطاقة هوية'),
                        SizedBox(height: 6),
                        Text('الحالة: جارٍ البحث'),
                      ],
                    ),
                  ),

                  //  بطاقة البلاغ رقم 3
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('رقم البلاغ: 1025', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('المفقود: حقيبة صغيرة'),
                        SizedBox(height: 6),
                        Text('الحالة: جاهز للاستلام'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE9D8C3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ما زلت تبحث عن مفقودك؟ رددّ دعاء الضالة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"اللهم ربّ الضالة, رد علي ضالتي"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: mainGreen,
                      height: 1.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
