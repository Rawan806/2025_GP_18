import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   
  Future<void> ensureInitialized() async {
    try { 
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  bool get isLoggedIn {
    try {
      return _auth.currentUser != null;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // تسجيل دخول بالإيميل وكلمة المرور
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // إنشاء حساب جديد
  Future<UserCredential?> createUserWithEmailAndPassword(
      String email, String password, String name, String phone, String userType) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // حفظ بيانات المستخدم في Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'userType': userType, // 'visitor' or 'staff'
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return result;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // الحصول على نوع المستخدم من Firestore
  Future<String?> getUserType() async {
    try {
      if (currentUser == null) return null;
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['userType'];
      }
      return null;
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }

  // تسجيل خروج
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}