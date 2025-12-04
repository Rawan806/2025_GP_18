import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations_helper.dart';

class VisitorProfile extends StatefulWidget {
  const VisitorProfile({super.key});

  @override
  State<VisitorProfile> createState() => _VisitorProfileState();
}

class _VisitorProfileState extends State<VisitorProfile> {
  // الألوان المعتمدة
  static const Color mainGreen = Color(0xFF243E36);
  static const Color beige = Color(0xFFC3BFB0);
  
  // بيانات المستخدم
  String _userName = '-';
  String _userPhone = '-';
  String _userEmail = '-';
  bool _isLoading = true;
  
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'current_user_id';  
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      if (_currentUserId == 'current_user_id') {
        // لا يوجد مستخدم مسجل دخول
        setState(() {
          _userName = '-';
          _userPhone = '-';
          _userEmail = '-';
          _isLoading = false;
        });
        return;
      }
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _userName = userData['name']?.toString() ?? 
                     userData['fullName']?.toString() ?? '-';
          _userPhone = userData['phone']?.toString() ?? 
                      userData['phoneNumber']?.toString() ?? '-';
          _userEmail = userData['email']?.toString() ?? '-';
          _isLoading = false;
        });
      } else {
        setState(() {
          _userName = '-';
          _userPhone = '-';
          _userEmail = '-';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _userName = '-';
        _userPhone = '-';
        _userEmail = '-';
        _isLoading = false;
      });
    }
  }
  
  void _showEditDialog(BuildContext context, Locale currentLocale) {
    final nameController = TextEditingController(text: _userName);
    final phoneController = TextEditingController(text: _userPhone);
    final emailController = TextEditingController(text: _userEmail);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.translate('editPersonalInfo', currentLocale.languageCode),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.translate('name', currentLocale.languageCode),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.translate('phoneNumber', currentLocale.languageCode),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.translate('email', currentLocale.languageCode),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              currentLocale.languageCode == 'ar' ? 'إلغاء' : 'Cancel',
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateUserInfo(
                nameController.text.trim(),
                phoneController.text.trim(),
                emailController.text.trim(),
                currentLocale,
              );
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
            child: Text(
              AppLocalizations.translate('save', currentLocale.languageCode),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateUserInfo(
    String name, 
    String phone, 
    String email,
    Locale currentLocale,
  ) async {
    try {
      if (_currentUserId == 'current_user_id') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLocale.languageCode == 'ar' 
                  ? 'لا يوجد مستخدم مسجل دخول' 
                  : 'No user logged in',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({
        'name': name,
        'phone': phone,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _userName = name;
        _userPhone = phone;
        _userEmail = email;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLocale.languageCode == 'ar' 
                  ? 'تم تحديث المعلومات بنجاح' 
                  : 'Information updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showChangePasswordDialog(BuildContext context, Locale currentLocale) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.translate('changePassword', currentLocale.languageCode),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: InputDecoration(
                  labelText: currentLocale.languageCode == 'ar' 
                      ? 'كلمة المرور الحالية' 
                      : 'Current Password',
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: currentLocale.languageCode == 'ar' 
                      ? 'كلمة المرور الجديدة' 
                      : 'New Password',
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.translate('confirmPassword', currentLocale.languageCode),
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              currentLocale.languageCode == 'ar' ? 'إلغاء' : 'Cancel',
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.translate('passwordMismatch', currentLocale.languageCode),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              await _changePassword(
                currentPasswordController.text,
                newPasswordController.text,
                currentLocale,
              );
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
            child: Text(
              AppLocalizations.translate('save', currentLocale.languageCode),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
    Locale currentLocale,
  ) async {
    try {
      if (_currentUserId == 'current_user_id') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLocale.languageCode == 'ar' 
                  ? 'لا يوجد مستخدم مسجل دخول' 
                  : 'No user logged in',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // التحقق من كلمة المرور الحالية
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final userData = userDoc.data()!;
      final storedPassword = userData['password']?.toString() ?? '';
      
      if (storedPassword != currentPassword) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                currentLocale.languageCode == 'ar' 
                    ? 'كلمة المرور الحالية غير صحيحة' 
                    : 'Current password is incorrect',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // تحديث كلمة المرور
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({
        'password': newPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLocale.languageCode == 'ar' 
                  ? 'تم تغيير كلمة المرور بنجاح' 
                  : 'Password changed successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: beige,
        appBar: AppBar(
          backgroundColor: mainGreen,
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppLocalizations.translate('accountSettings', currentLocale.languageCode),
            style: const TextStyle(color: Colors.white),
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

                _isLoading
                    ? const CircularProgressIndicator(color: mainGreen)
                    : Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: mainGreen,
                        ),
                      ),

                const SizedBox(height: 24),

                Text(
                  AppLocalizations.translate('personalInfo', currentLocale.languageCode),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black.withOpacity(0.6),
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: mainGreen),
                        ),
                      )
                    : Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.4),
                          1: FlexColumnWidth(1.6),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(children: [
                            _ProfileLabel(AppLocalizations.translate('name', currentLocale.languageCode)),
                            _ProfileValue(_userName),
                          ]),
                          const TableRow(children: [
                            SizedBox(height: 14), SizedBox(height: 14),
                          ]),
                          TableRow(children: [
                            _ProfileLabel(AppLocalizations.translate('phoneNumber', currentLocale.languageCode)),
                            _ProfileValue(_userPhone),
                          ]),
                          const TableRow(children: [
                            SizedBox(height: 14), SizedBox(height: 14),
                          ]),
                          TableRow(children: [
                            _ProfileLabel(AppLocalizations.translate('email', currentLocale.languageCode)),
                            _ProfileValue(_userEmail),
                          ]),
                        ],
                      ),

                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading 
                        ? null 
                        : () => _showEditDialog(context, currentLocale),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                      elevation: 2,
                    ),
                    child: Text(
                      AppLocalizations.translate('editPersonalInfo', currentLocale.languageCode), 
                      style: const TextStyle(fontSize: 16)
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading 
                        ? null 
                        : () => _showChangePasswordDialog(context, currentLocale),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                      elevation: 2,
                    ),
                    child: Text(
                      AppLocalizations.translate('changePassword', currentLocale.languageCode), 
                      style: const TextStyle(fontSize: 16)
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _ProfileLabel extends StatelessWidget {
  final String text;
  const _ProfileLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    
    return Text(
      text,
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
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
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    
    return Text(
      text,
      textAlign: isArabic ? TextAlign.left : TextAlign.right,
      style: const TextStyle(
        fontSize: 18,
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
