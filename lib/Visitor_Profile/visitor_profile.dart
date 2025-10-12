import 'package:flutter/material.dart';

class VisitorProfile extends StatelessWidget {
  const VisitorProfile({super.key});

  // الألوان المعتمدة
  static const Color mainGreen = Color(0xFF243E36);
  static const Color beige = Color(0xFFC3BFB0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        backgroundColor: mainGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'إعدادات الحساب',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Container(height: 120, color: mainGreen),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(top: 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // إطار
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: mainGreen, width: 5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const CircleAvatar(
                        radius: 56,
                        backgroundColor: Color(0xFFEEEEEE),
                        child: Icon(Icons.person, size: 56, color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // dummy information
                const Text(
                  'روان',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: mainGreen,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'المعلومات الشخصية',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black.withOpacity(0.6),
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.4),
                      1: FlexColumnWidth(1.6),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: const [
                      TableRow(children: [
                        _ProfileLabel('الاسم'),
                        _ProfileValue('روان'),
                      ]),
                      TableRow(children: [
                        SizedBox(height: 14), SizedBox(height: 14),
                      ]),
                      TableRow(children: [
                        _ProfileLabel('رقم الجوال'),
                        _ProfileValue('0500000000'),
                      ]),
                      TableRow(children: [
                        SizedBox(height: 14), SizedBox(height: 14),
                      ]),
                      TableRow(children: [
                        _ProfileLabel('البريد الإلكتروني'),
                        _ProfileValue('rawan@gmail.com'),
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () { //Laterr
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text(' تعديل المعلومات')),
                      // );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                      elevation: 2,
                    ),
                    child: const Text('تعديل المعلومات الشخصية', style: TextStyle(fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () { // we will do it later
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text('')),
                      // );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                      elevation: 2,
                    ),
                    child: const Text('تعديل كلمة المرور', style: TextStyle(fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLabel extends StatelessWidget {
  final String text;
  const _ProfileLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: 16,
        color: Colors.black.withOpacity(0.65),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ProfileValue extends StatelessWidget {
  final String text;
  const _ProfileValue(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 18,
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
