import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../HomePage/HomePage.dart';
import '../services/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneE164;
  final String name;
  final String email;
  final String userType;

  // إذا تبين بعد التحقق يروح مباشرة Home
  final bool onVerifiedNavigateToHome;

  const OtpVerificationScreen({
    super.key,
    required this.phoneE164,
    required this.name,
    required this.email,
    required this.userType,
    this.onVerifiedNavigateToHome = true,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  String? _verificationId;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _error;

  int _secondsLeft = 60;
  Timer? _timer;
  int? _forceResendingToken;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSending = true;
      _error = null;
    });

    _startTimer();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneE164,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _forceResendingToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // أحيانًا أندرويد يسوي auto-retrieval
          try {
            final user = _auth.currentUser;
            if (user == null) return;

            await user.linkWithCredential(credential);

            // اختياري: حفظ بروفايل بعد الربط
            // إذا AuthService عندك يسوي firestore update، استدعيه هنا
            // await _authService.saveUserProfile(user.uid, widget.name, widget.phoneE164, widget.userType);

            if (!mounted) return;
            _goHome();
          } catch (e) {
            if (!mounted) return;
            setState(() => _error = 'فشل التحقق التلقائي: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _error = 'فشل إرسال الكود: ${e.message ?? e.code}';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _forceResendingToken = resendToken;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'خطأ غير متوقع أثناء إرسال الكود: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();
    final code = _otpController.text.trim();

    if (code.length < 6) {
      setState(() => _error = 'اكتبي رمز التحقق كامل (6 أرقام)');
      return;
    }
    if (_verificationId == null) {
      setState(() => _error = 'لا يوجد verificationId. اعيدي إرسال الكود.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _error = 'الجلسة انتهت. سجلي دخول من جديد.');
        return;
      }

      // هذا أهم سطر: ربط رقم الجوال بنفس حساب الإيميل
      await user.linkWithCredential(credential);

      // اختياري: حفظ بروفايل بعد الربط
      // await _authService.saveUserProfile(user.uid, widget.name, widget.phoneE164, widget.userType);

      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? e.code;
      if (e.code == 'invalid-verification-code') {
        msg = 'رمز التحقق غير صحيح';
      } else if (e.code == 'credential-already-in-use') {
        msg = 'هذا الرقم مربوط بحساب آخر';
      }
      if (!mounted) return;
      setState(() => _error = msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'خطأ غير متوقع: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isVerifying = false);
    }
  }

  void _goHome() {
    if (!widget.onVerifiedNavigateToHome) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد رقم الجوال'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'أرسلنا رمز تحقق إلى:\n${widget.phoneE164}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'رمز التحقق (OTP)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                errorText: _error,
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: (_isVerifying || _isSending) ? null : _verifyCode,
              child: _isVerifying
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('تأكيد'),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: (_secondsLeft == 0 && !_isSending) ? _sendCode : null,
              child: Text(
                _secondsLeft == 0
                    ? 'إعادة إرسال الكود'
                    : 'إعادة الإرسال بعد $_secondsLeft ثانية',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
