import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HandoverFormPage extends StatefulWidget {
  final String foundItemId;
  final String? lostReportId;

  const HandoverFormPage({
    super.key,
    required this.foundItemId,
    this.lostReportId,
  });

  @override
  State<HandoverFormPage> createState() => _HandoverFormPageState();
}

class _HandoverFormPageState extends State<HandoverFormPage> {
  static const Color mainGreen = Color(0xFF243E36);
  static const Color beigeColor = Color(0xFFC3BFB0);

  final pinController = TextEditingController();
  final recipientNameController = TextEditingController();
  final recipientIdController = TextEditingController();
  final recipientPhoneController = TextEditingController();
  final staffNotesController = TextEditingController();
  final typedSignatureController = TextEditingController();

  String _idVerificationMethod = 'National ID';
  String _itemCondition = 'Good';
  bool _pinVerified = false;
  bool _disclaimerAccepted = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  Map<String, dynamic>? foundItem;
  Map<String, dynamic>? lostReport;

  @override
  void initState() {
    super.initState();
    _loadHandoverData();
  }

  @override
  void dispose() {
    pinController.dispose();
    recipientNameController.dispose();
    recipientIdController.dispose();
    recipientPhoneController.dispose();
    staffNotesController.dispose();
    typedSignatureController.dispose();
    super.dispose();
  }

  Future<void> _loadHandoverData() async {
    try {
      final foundDoc = await FirebaseFirestore.instance
          .collection('foundItems')
          .doc(widget.foundItemId)
          .get();

      if (!foundDoc.exists) {
        throw Exception('Found item not found');
      }

      final foundData = foundDoc.data() ?? {};
      final linkedLostId =
          widget.lostReportId ??
              (foundData['linkedLostReportId'] ??
                  foundData['matchedLostItemId'] ??
                  '')
                  .toString();

      Map<String, dynamic>? lostData;

      if (linkedLostId.isNotEmpty) {
        final lostDoc = await FirebaseFirestore.instance
            .collection('lostItems')
            .doc(linkedLostId)
            .get();

        if (lostDoc.exists) {
          lostData = lostDoc.data();
          lostData?['docId'] = lostDoc.id;
        }
      }

      setState(() {
        foundItem = foundData;
        foundItem?['docId'] = foundDoc.id;
        lostReport = lostData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error loading handover data: $e', Colors.red);
    }
  }

  void _verifyPin() {
    final enteredPin = pinController.text.trim();
    final storedPin = (foundItem?['handoverPin'] ?? '').toString();
    final isPinUsed = foundItem?['isPinUsed'] == true;
    final status = (foundItem?['status'] ?? '').toString();

    if (enteredPin.isEmpty) {
      _showSnack('Please enter the PIN', Colors.orange);
      return;
    }

    if (status != 'ready_to_handover') {
      _showSnack('This item is not ready for handover', Colors.red);
      return;
    }

    if (isPinUsed) {
      _showSnack('This PIN has already been used', Colors.red);
      return;
    }

    if (enteredPin == storedPin) {
      setState(() => _pinVerified = true);
      _showSnack('PIN verified successfully', Colors.green);
    } else {
      setState(() => _pinVerified = false);
      _showSnack('Incorrect PIN', Colors.red);
    }
  }

  Future<void> _confirmHandover() async {
    if (!_pinVerified) {
      _showSnack('Please verify the PIN first', Colors.orange);
      return;
    }

    if (recipientNameController.text.trim().isEmpty ||
        recipientIdController.text.trim().isEmpty ||
        recipientPhoneController.text.trim().isEmpty ||
        typedSignatureController.text.trim().isEmpty) {
      _showSnack('Please fill all required fields', Colors.orange);
      return;
    }

    if (!_disclaimerAccepted) {
      _showSnack('Please accept the disclaimer', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final foundId = widget.foundItemId;
      final lostId = widget.lostReportId ??
          (foundItem?['linkedLostReportId'] ??
              foundItem?['matchedLostItemId'] ??
              '')
              .toString();

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
        'idVerificationMethod': _idVerificationMethod,
        'itemConditionAtHandover': _itemCondition,
        'typedSignature': typedSignatureController.text.trim(),
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
          'idVerificationMethod': _idVerificationMethod,
          'itemConditionAtHandover': _itemCondition,
          'typedSignature': typedSignatureController.text.trim(),
          'disclaimerAccepted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final logRef = FirebaseFirestore.instance.collection('handoverLogs').doc();

      batch.set(logRef, {
        'foundItemId': foundId,
        'lostReportId': lostId,
        'handoverPin': foundItem?['handoverPin'],
        'pinVerified': true,
        'recipientFullName': recipientNameController.text.trim(),
        'recipientIdNumber': recipientIdController.text.trim(),
        'recipientPhone': recipientPhoneController.text.trim(),
        'idVerificationMethod': _idVerificationMethod,
        'itemConditionAtHandover': _itemCondition,
        'typedSignature': typedSignatureController.text.trim(),
        'disclaimerAccepted': true,
        'staffNotes': staffNotesController.text.trim(),
        'action': 'handover_completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;

      _showSnack('Item handed over successfully', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Error completing handover: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image =
    (foundItem?['imageUrl'] ?? foundItem?['imagePath'] ?? '').toString();
    final title = (foundItem?['title'] ?? foundItem?['type'] ?? '-').toString();
    final location =
    (foundItem?['storageLocation'] ?? foundItem?['foundLocation'] ?? '-')
        .toString();
    final lostTitle = (lostReport?['title'] ?? '-').toString();
    final storedPin = (foundItem?['handoverPin'] ?? '').toString();

    return Scaffold(
      backgroundColor: beigeColor,
      appBar: AppBar(
        backgroundColor: mainGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Handover Form'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (image.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    image,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  ),
                )
              else
                _imagePlaceholder(),

              const SizedBox(height: 16),

              _infoRow('Found Item', title),
              _infoRow('Linked Lost Report', lostTitle),
              _infoRow('Storage / Location', location),
              _infoRow('PIN Status', storedPin.isEmpty ? 'No PIN' : 'PIN generated'),

              const Divider(height: 28),

              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                decoration: _dec('Enter PIN shown by user'),
              ),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: _verifyPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.verified_user),
                label: const Text('Verify PIN'),
              ),

              if (_pinVerified) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PIN verified. Please complete the recipient form.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: recipientNameController,
                  decoration: _dec('Recipient Full Name *'),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: recipientIdController,
                  keyboardType: TextInputType.number,
                  decoration: _dec('National ID / Student ID *'),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: recipientPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _dec('Phone Number *'),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _idVerificationMethod,
                  decoration: _dec('ID Verification Method'),
                  items: const [
                    DropdownMenuItem(
                      value: 'National ID',
                      child: Text('National ID'),
                    ),
                    DropdownMenuItem(
                      value: 'Student ID',
                      child: Text('Student ID'),
                    ),
                    DropdownMenuItem(
                      value: 'Phone Verification',
                      child: Text('Phone Verification'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _idVerificationMethod = value);
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _itemCondition,
                  decoration: _dec('Item Condition at Handover'),
                  items: const [
                    DropdownMenuItem(value: 'Good', child: Text('Good')),
                    DropdownMenuItem(
                      value: 'Damaged',
                      child: Text('Damaged'),
                    ),
                    DropdownMenuItem(
                      value: 'Needs Review',
                      child: Text('Needs Review'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _itemCondition = value);
                  },
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: typedSignatureController,
                  decoration: _dec('Typed Signature / Full Name *'),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: staffNotesController,
                  maxLines: 3,
                  decoration: _dec('Staff Notes'),
                ),

                const SizedBox(height: 12),

                CheckboxListTile(
                  value: _disclaimerAccepted,
                  onChanged: (value) {
                    setState(() {
                      _disclaimerAccepted = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I confirm that the recipient has received the item, and the Lost & Found office is no longer responsible for it after handover.',
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _confirmHandover,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: _isSubmitting
                      ? const Text('Submitting...')
                      : const Text('Confirm Physical Handover'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 44),
      ),
    );
  }
}
