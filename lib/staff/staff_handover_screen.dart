import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StaffHandoverScreen extends StatefulWidget {
  const StaffHandoverScreen({super.key});

  @override
  State<StaffHandoverScreen> createState() => _StaffHandoverScreenState();
}

class _StaffHandoverScreenState extends State<StaffHandoverScreen> {
  static const Color mainGreen = Color(0xFF243E36);
  static const Color beigeColor = Color(0xFFC3BFB0);

  final TextEditingController pinController = TextEditingController();
  final TextEditingController recipientNameController = TextEditingController();
  final TextEditingController recipientIdController = TextEditingController();
  final TextEditingController recipientPhoneController = TextEditingController();
  final TextEditingController staffNotesController = TextEditingController();

  Map<String, dynamic>? selectedItem;
  String? selectedFoundId;
  bool pinVerified = false;
  bool disclaimerAccepted = false;
  bool isLoading = false;

  @override
  void dispose() {
    pinController.dispose();
    recipientNameController.dispose();
    recipientIdController.dispose();
    recipientPhoneController.dispose();
    staffNotesController.dispose();
    super.dispose();
  }

  Future<void> verifyPin() async {
    if (selectedItem == null || selectedFoundId == null) return;

    final enteredPin = pinController.text.trim();
    final storedPin = (selectedItem!['handoverPin'] ?? '').toString();
    final status = (selectedItem!['status'] ?? '').toString();
    final isPinUsed = selectedItem!['isPinUsed'] == true;

    if (enteredPin.isEmpty) {
      _snack('Please enter PIN', Colors.orange);
      return;
    }

    if (status != 'ready_to_handover') {
      _snack('This item is not ready for handover', Colors.red);
      return;
    }

    if (isPinUsed) {
      _snack('This PIN was already used', Colors.red);
      return;
    }

    if (enteredPin == storedPin) {
      setState(() => pinVerified = true);
      _snack('PIN verified successfully', Colors.green);
    } else {
      setState(() => pinVerified = false);
      _snack('Wrong PIN', Colors.red);
    }
  }

  Future<void> confirmHandover() async {
    if (selectedItem == null || selectedFoundId == null) return;

    if (!pinVerified) {
      _snack('Please verify PIN first', Colors.orange);
      return;
    }

    if (recipientNameController.text.trim().isEmpty ||
        recipientIdController.text.trim().isEmpty ||
        recipientPhoneController.text.trim().isEmpty) {
      _snack('Please fill recipient information', Colors.orange);
      return;
    }

    if (!disclaimerAccepted) {
      _snack('Please accept the disclaimer', Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      final foundId = selectedFoundId!;
      final lostId = (selectedItem!['linkedLostReportId'] ??
          selectedItem!['matchedLostItemId'] ??
          '')
          .toString();
      final userId = (selectedItem!['linkedUserId'] ?? '').toString();

      final batch = FirebaseFirestore.instance.batch();

      final foundRef =
      FirebaseFirestore.instance.collection('foundItems').doc(foundId);

      batch.update(foundRef, {
        'status': 'completed',
        'handoverStatus': 'completed',
        'isPinUsed': true,
        'handoverConfirmedAt': FieldValue.serverTimestamp(),
        'recipientFullName': recipientNameController.text.trim(),
        'recipientIdNumber': recipientIdController.text.trim(),
        'recipientPhone': recipientPhoneController.text.trim(),
        'disclaimerAccepted': true,
        'staffNotes': staffNotesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (lostId.isNotEmpty) {
        final lostRef =
        FirebaseFirestore.instance.collection('lostItems').doc(lostId);

        batch.update(lostRef, {
          'status': 'completed',
          'handoverStatus': 'completed',
          'isPinUsed': true,
          'handoverConfirmedAt': FieldValue.serverTimestamp(),
          'recipientFullName': recipientNameController.text.trim(),
          'recipientIdNumber': recipientIdController.text.trim(),
          'recipientPhone': recipientPhoneController.text.trim(),
          'disclaimerAccepted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final logRef = FirebaseFirestore.instance.collection('handoverLogs').doc();

      batch.set(logRef, {
        'foundItemId': foundId,
        'lostReportId': lostId,
        'userId': userId,
        'action': 'handover_completed',
        'pinVerified': true,
        'recipientFullName': recipientNameController.text.trim(),
        'recipientIdNumber': recipientIdController.text.trim(),
        'recipientPhone': recipientPhoneController.text.trim(),
        'disclaimerAccepted': true,
        'staffNotes': staffNotesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      _snack('Item handed over successfully', Colors.green);

      setState(() {
        selectedItem = null;
        selectedFoundId = null;
        pinVerified = false;
        disclaimerAccepted = false;
        pinController.clear();
        recipientNameController.clear();
        recipientIdController.clear();
        recipientPhoneController.clear();
        staffNotesController.clear();
      });
    } catch (e) {
      _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void selectItem(String id, Map<String, dynamic> data) {
    setState(() {
      selectedFoundId = id;
      selectedItem = data;
      pinVerified = false;
      disclaimerAccepted = false;
      pinController.clear();
      recipientNameController.clear();
      recipientIdController.clear();
      recipientPhoneController.clear();
      staffNotesController.clear();
    });
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeColor,
      appBar: AppBar(
        backgroundColor: mainGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Staff Handover'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
        children: [
          Expanded(
            flex: 1,
            child: _readyItemsList(),
          ),
          Expanded(
            flex: 1,
            child: _handoverPanel(),
          ),
        ],
      ),
    );
  }

  Widget _readyItemsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('foundItems')
          .where('status', isEqualTo: 'ready_to_handover')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading ready items'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No items ready for handover'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final image = (data['imageUrl'] ?? data['imagePath'] ?? '').toString();
            final title = (data['title'] ?? data['type'] ?? 'Found Item').toString();
            final lostId =
            (data['linkedLostReportId'] ?? data['matchedLostItemId'] ?? '')
                .toString();

            final isSelected = selectedFoundId == doc.id;

            return InkWell(
              onTap: () => selectItem(doc.id, data),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? mainGreen : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: image.isNotEmpty
                          ? Image.network(
                        image,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                          : _placeholder(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Found ID: ${doc.id}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Lost ID: $lostId', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey.shade300,
      child: const Icon(Icons.image_not_supported),
    );
  }

  Widget _handoverPanel() {
    if (selectedItem == null) {
      return const Center(child: Text('Select an item to start handover'));
    }

    final title = (selectedItem!['title'] ?? selectedItem!['type'] ?? '-').toString();
    final storedPin = (selectedItem!['handoverPin'] ?? '').toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Handover Form',
              style: TextStyle(
                color: mainGreen,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text('Item: $title'),
            Text('Found ID: $selectedFoundId'),
            const SizedBox(height: 18),

            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              decoration: _dec('Enter PIN shown by user'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: verifyPin,
              style: ElevatedButton.styleFrom(
                backgroundColor: mainGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.verified_user),
              label: const Text('Verify PIN'),
            ),

            if (pinVerified) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Text('PIN verified: $storedPin'),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: recipientNameController,
                decoration: _dec('Recipient Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: recipientIdController,
                decoration: _dec('National ID / Student ID'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: recipientPhoneController,
                keyboardType: TextInputType.phone,
                decoration: _dec('Phone Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: staffNotesController,
                maxLines: 3,
                decoration: _dec('Staff Notes (optional)'),
              ),
              const SizedBox(height: 12),

              CheckboxListTile(
                value: disclaimerAccepted,
                onChanged: (value) {
                  setState(() {
                    disclaimerAccepted = value ?? false;
                  });
                },
                title: const Text(
                  'I confirm that the recipient received the item and the Lost & Found office is no longer responsible after handover.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: confirmHandover,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text('Confirm Physical Handover'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}