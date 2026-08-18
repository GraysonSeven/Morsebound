import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../learning/learning_model.dart';
import '../profile/career_profile.dart';
import '../profile/career_store.dart';
import '../settings/app_settings.dart';
import '../settings/settings_store.dart';
import '../storage/progress_store.dart';
import 'cloud_sync_hook.dart';

class CloudAccountState {
  const CloudAccountState({required this.available, required this.user, required this.syncing, this.lastSync, this.error});
  const CloudAccountState.unavailable() : available=false, user=null, syncing=false, lastSync=null, error=null;
  final bool available;
  final User? user;
  final bool syncing;
  final DateTime? lastSync;
  final String? error;
  bool get signedIn => user != null;
  CloudAccountState copyWith({bool? available, User? user, bool clearUser=false, bool? syncing, DateTime? lastSync, String? error, bool clearError=false}) => CloudAccountState(
    available: available ?? this.available,
    user: clearUser ? null : (user ?? this.user),
    syncing: syncing ?? this.syncing,
    lastSync: lastSync ?? this.lastSync,
    error: clearError ? null : (error ?? this.error),
  );
}

class CloudAccountService {
  CloudAccountService._();
  static final CloudAccountService instance = CloudAccountService._();
  final ValueNotifier<CloudAccountState> state = ValueNotifier(const CloudAccountState.unavailable());
  final ProgressStore _progressStore = ProgressStore();
  final CareerStore _careerStore = CareerStore();
  final SettingsStore _settingsStore = SettingsStore();
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  Timer? _debounce;
  bool _initialized=false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized=true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      _auth=FirebaseAuth.instance;
      _firestore=FirebaseFirestore.instance;
      if (kIsWeb) await _auth!.setPersistence(Persistence.LOCAL);
      state.value=CloudAccountState(available:true,user:_auth!.currentUser,syncing:false);
      CloudSyncHook.onLocalChanged=_scheduleSync;
      _auth!.authStateChanges().listen((user){
        state.value=CloudAccountState(available:true,user:user,syncing:false,lastSync:state.value.lastSync);
        if (user!=null) unawaited(syncNow());
      });
      if (_auth!.currentUser!=null) await syncNow();
    } catch (error) {
      state.value=CloudAccountState(available:false,user:null,syncing:false,error:error.toString());
    }
  }

  Future<void> createAccount({required String email, required String password}) async {
    final auth=_requireAuth();
    try {
      _clearError();
      await auth.createUserWithEmailAndPassword(email:email.trim(),password:password);
      await syncNow();
    } on FirebaseAuthException catch(e) { _setError(_friendlyAuthError(e)); rethrow; }
  }

  Future<void> signIn({required String email, required String password}) async {
    final auth=_requireAuth();
    try {
      _clearError();
      await auth.signInWithEmailAndPassword(email:email.trim(),password:password);
      await syncNow();
    } on FirebaseAuthException catch(e) { _setError(_friendlyAuthError(e)); rethrow; }
  }

  Future<void> signInWithGoogle() async {
    final auth = _requireAuth();

    try {
      _clearError();

      if (kIsWeb) {
        await auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize();

        final googleUser = await googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        await auth.signInWithCredential(credential);
      }

      await syncNow();
    } on FirebaseAuthException catch (error) {
      _setError(_friendlyAuthError(error));
      rethrow;
    } catch (error) {
      _setError(error.toString());
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final auth=_requireAuth();
    try { _clearError(); await auth.sendPasswordResetEmail(email:email.trim()); }
    on FirebaseAuthException catch(e) { _setError(_friendlyAuthError(e)); rethrow; }
  }

  Future<void> signOut() async {
    _debounce?.cancel();
    await _requireAuth().signOut();
    state.value=CloudAccountState(available:true,user:null,syncing:false,lastSync:state.value.lastSync);
  }

  Future<void> deleteCloudAccount() async {
    final auth=_requireAuth();
    final user=auth.currentUser;
    if (user==null) return;
    try {
      _clearError();
      await _requireFirestore().collection('users').doc(user.uid).collection('state').doc('current').delete();
      await user.delete();
      state.value=const CloudAccountState(available:true,user:null,syncing:false);
    } on FirebaseAuthException catch(e) { _setError(_friendlyAuthError(e)); rethrow; }
    catch(e) { _setError(e.toString()); rethrow; }
  }

  Future<void> syncNow() async {
    final user=_auth?.currentUser;
    final firestore=_firestore;
    if (user==null || firestore==null || state.value.syncing) return;
    _debounce?.cancel();
    state.value=state.value.copyWith(syncing:true,clearError:true);
    try {
      final ref=firestore.collection('users').doc(user.uid).collection('state').doc('current');
      final remote=await ref.get();
      final now=DateTime.now().millisecondsSinceEpoch;
      var learning=await _progressStore.load();
      var career=await _careerStore.load();
      var settings=await _settingsStore.load();
      var learningMs=await _progressStore.updatedAtMs();
      var careerMs=await _careerStore.updatedAtMs();
      var settingsMs=await _settingsStore.updatedAtMs();
      if (!remote.exists) {
        learningMs=learningMs==0?now:learningMs;
        careerMs=careerMs==0?now:careerMs;
        settingsMs=settingsMs==0?now:settingsMs;
        await _progressStore.restoreFromCloud(learning,learningMs);
        await _careerStore.restoreFromCloud(career,careerMs);
        await _settingsStore.restoreFromCloud(settings,settingsMs);
        await _writeSnapshot(ref,learning,career,settings,learningMs,careerMs,settingsMs);
      } else {
        final data=remote.data() ?? const <String,dynamic>{};
        final rLearning=(data['learningUpdatedMs'] as num?)?.toInt() ?? 0;
        final rCareer=(data['careerUpdatedMs'] as num?)?.toInt() ?? 0;
        final rSettings=(data['settingsUpdatedMs'] as num?)?.toInt() ?? 0;
        var localWins=false;
        if (rLearning>learningMs && data['learning'] is Map) {
          learning=LearningSnapshot.fromJson(Map<String,dynamic>.from(data['learning'] as Map));
          learningMs=rLearning;
          await _progressStore.restoreFromCloud(learning,learningMs);
        } else if (learningMs>rLearning) { localWins=true; }
        if (rCareer>careerMs && data['career'] is Map) {
          career=CareerProfile.fromJson(Map<String,dynamic>.from(data['career'] as Map));
          careerMs=rCareer;
          await _careerStore.restoreFromCloud(career,careerMs);
        } else if (careerMs>rCareer) { localWins=true; }
        if (rSettings>settingsMs && data['settings'] is Map) {
          settings=AppSettings.fromJson(Map<String,dynamic>.from(data['settings'] as Map));
          settingsMs=rSettings;
          await _settingsStore.restoreFromCloud(settings,settingsMs);
        } else if (settingsMs>rSettings) { localWins=true; }
        if (localWins) {
          await _writeSnapshot(ref,await _progressStore.load(),await _careerStore.load(),await _settingsStore.load(),await _progressStore.updatedAtMs(),await _careerStore.updatedAtMs(),await _settingsStore.updatedAtMs());
        }
      }
      state.value=state.value.copyWith(syncing:false,lastSync:DateTime.now(),clearError:true);
    } catch(e) {
      state.value=state.value.copyWith(syncing:false,error:e.toString());
    }
  }

  void _scheduleSync() {
    if (_auth?.currentUser==null) return;
    _debounce?.cancel();
    _debounce=Timer(const Duration(seconds:2),()=>unawaited(syncNow()));
  }

  Future<void> _writeSnapshot(DocumentReference<Map<String,dynamic>> ref, LearningSnapshot learning, CareerProfile career, AppSettings settings, int learningMs, int careerMs, int settingsMs) async {
    await ref.set({
      'schema':1,
      'learning':learning.toJson(),
      'career':career.toJson(),
      'settings':settings.toJson(),
      'learningUpdatedMs':learningMs,
      'careerUpdatedMs':careerMs,
      'settingsUpdatedMs':settingsMs,
      'updatedAt':FieldValue.serverTimestamp(),
    },SetOptions(merge:true));
  }

  FirebaseAuth _requireAuth() {
    if (_auth==null || !state.value.available) throw StateError('Morsebound cloud account service is not configured.');
    return _auth!;
  }
  FirebaseFirestore _requireFirestore() {
    if (_firestore==null || !state.value.available) throw StateError('Morsebound cloud storage is not configured.');
    return _firestore!;
  }
  void _clearError()=>state.value=state.value.copyWith(clearError:true);
  void _setError(String m)=>state.value=state.value.copyWith(error:m);
  String _friendlyAuthError(FirebaseAuthException e) {
    switch(e.code) {
      case 'email-already-in-use': return 'An account already exists for this email.';
      case 'invalid-email': return 'Enter a valid email address.';
      case 'weak-password': return 'Use a stronger password.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found': return 'Email or password is incorrect.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      case 'requires-recent-login': return 'Please sign in again before deleting the account.';
      default: return e.message ?? e.code;
    }
  }
}
