import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) return 'فشل إنشاء الحساب';

      await user.updateDisplayName(name);

      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email.trim(),
        'role': 'user',
        'status': 'active',
        'pointsBalance': 0,
        'totalPointsEarned': 0,
        'totalPointsSpent': 0,
        'withdrawableBalance': 0.0,
        'referralCode': user.uid.substring(0, 6).toUpperCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return _getAuthError(e.code);
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _getAuthError(e.code);
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _getAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'user-not-found':
        return 'الحساب غير موجود';
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      default:
        return 'حدث خطأ أثناء تسجيل الدخول';
    }
  }
}
