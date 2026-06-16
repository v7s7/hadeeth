import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/user_gender.dart';
import '../models/user_role.dart';

/// يمثل حالة جلسة المستخدم (ضيف أو مسجّل) باستخدام Firebase Auth.
///
/// إن لم تكن Firebase مهيّأة يبقى المستخدم في وضع الضيف دون أي خطأ. عند
/// تسجيل الدخول يُحمَّل ملف المستخدم من Firestore (users/{uid}) ليحدد دوره
/// (مستخدم عادي أو مشرف عام) وحالة حسابه (مفعّل/معطّل).
class SessionService extends ChangeNotifier {
  User? _user;
  AppUser? _profile;
  bool _isLoading = false;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSubscription;

  SessionService() {
    _listenToAuth();
  }

  void _listenToAuth() {
    try {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        (user) {
          _user = user;
          _profileSubscription?.cancel();
          _profileSubscription = null;
          _profile = null;

          if (user != null) {
            _listenToProfile(user);
          }
          notifyListeners();
        },
        onError: (_) {},
      );
    } catch (_) {
      // Firebase غير مهيّأ؛ يبقى المستخدم في وضع الضيف.
    }
  }

  void _listenToProfile(User user) {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    _profileSubscription = docRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final profile = AppUser.fromMap(snapshot.id, snapshot.data()!);
        if (profile.isDisabled) {
          _profile = null;
          FirebaseAuth.instance.signOut();
          return;
        }
        _profile = profile;
      } else {
        final newProfile = AppUser(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          role: UserRole.user,
          isDisabled: false,
          createdAt: DateTime.now(),
        );
        docRef.set(newProfile.toMap());
        _profile = newProfile;
      }
      notifyListeners();
    }, onError: (_) {});
  }

  /// المستخدم ضيف ما دام لم يسجّل الدخول.
  bool get isGuest => _user == null;

  /// جنس المستخدم المسجَّل (null للضيف أو قبل إتمام الترحيب).
  UserGender? get gender => _profile?.gender;

  /// الاسم المعروض، أو البريد الإلكتروني إن لم يُحدَّد اسم.
  String? get displayName {
    final name = _profile?.displayName;
    if (name != null && name.isNotEmpty) return name;
    return _user?.email;
  }

  /// هل المستخدم الحالي مشرف محتوى.
  bool get isAdmin => _profile?.role == UserRole.admin;

  /// هل المستخدم الحالي مشرف عام (له صلاحية الوصول إلى لوحة التحكم).
  bool get isSuperAdmin => _profile?.role == UserRole.superAdmin;

  /// هل المستخدم مشرف من أي نوع (مشرف محتوى أو مشرف عام).
  bool get isAnyAdmin => isAdmin || isSuperAdmin;

  /// حالة تحميل عمليات تسجيل الدخول/إنشاء الحساب.
  bool get isLoading => _isLoading;

  /// تسجيل الدخول بالبريد الإلكتروني وكلمة المرور.
  ///
  /// تُعيد رسالة خطأ بالعربية عند الفشل، أو null عند النجاح.
  Future<String?> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } catch (_) {
      return 'تعذّر تسجيل الدخول. تأكد من اتصالك بالإنترنت وإعداد Firebase.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// إنشاء حساب جديد بالبريد الإلكتروني وكلمة المرور.
  ///
  /// تُعيد رسالة خطأ بالعربية عند الفشل، أو null عند النجاح.
  Future<String?> registerWithEmail(String email, String password, String displayName) async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        final name = displayName.trim();
        if (name.isNotEmpty) {
          await user.updateDisplayName(name);
        }
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          AppUser(
            id: user.uid,
            email: email.trim(),
            displayName: name,
            role: UserRole.user,
            isDisabled: false,
            createdAt: DateTime.now(),
          ).toMap(),
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } catch (_) {
      return 'تعذّر إنشاء الحساب. تأكد من اتصالك بالإنترنت وإعداد Firebase.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تسجيل الخروج.
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب.';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مستخدم من قبل.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جدًا، اختر كلمة مرور أقوى.';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول مرة أخرى بعد قليل.';
      default:
        return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
