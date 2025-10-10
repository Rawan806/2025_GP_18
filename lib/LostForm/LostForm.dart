import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wadiah_app/HomePage/HomePage.dart';

class LostForm extends StatefulWidget {
  const LostForm({super.key});

  @override
  State<LostForm> createState() => _LostFormState();
}

class _LostFormState extends State<LostForm> {
  final Color mainGreen = const Color(0xFF255E4B);

  final TextEditingController dateController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  DateTime? selectedDate;

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          dateController.text =
              DateFormat('yyyy-MM-dd – HH:mm').format(selectedDate!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainGreen,
        title: const Text('نموذج الإبلاغ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: dateController,
              readOnly: true,
              onTap: _pickDateTime,
              decoration: InputDecoration(
                labelText: 'تاريخ ووقت الفقدان *',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today, color: mainGreen),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: itemNameController,
              decoration: const InputDecoration(
                labelText: 'اسم الغرض المفقود *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: () {
              },
              icon: Icon(Icons.upload, color: mainGreen),
              label: Text(
                'إرفاق صور للغرض',
                style: TextStyle(color: mainGreen),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: mainGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),

            // the tip
            Text(
              'ملاحظة: للمساعدة في العثور على الغرض المفقود، يُفضّل إرفاق صورة قديمة إن وُجدت، أو البحث عن صورة مشابهة من الإنترنت وإرفاقها.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'وصف إضافي (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: mainGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إرسال البلاغ بنجاح'),
                    duration: Duration(seconds: 1), // تظهر لمدة ثانية
                  ),
                );

                Future.delayed(const Duration(seconds: 1), () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                  );
                });
              },
              child: const Text(
                'إرسال البلاغ',
                style: TextStyle(fontSize: 18),
              ),
            )

          ],
        ),
      ),
    );
  }
}
