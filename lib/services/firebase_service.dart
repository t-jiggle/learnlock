import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnlock/models/child_profile.dart';
import 'package:learnlock/models/progress_record.dart';

class FirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---- Auth ----

  Future<UserCredential?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ---- Child Profiles ----

  CollectionReference<Map<String, dynamic>> get _children =>
      _firestore.collection('children');

  Future<List<ChildProfile>> getChildProfiles(String parentUid) async {
    final snap = await _children
        .where('parentUid', isEqualTo: parentUid)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map(ChildProfile.fromFirestore).toList();
  }

  Stream<List<ChildProfile>> watchChildProfiles(String parentUid) =>
      _children
          .where('parentUid', isEqualTo: parentUid)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((s) => s.docs.map(ChildProfile.fromFirestore).toList());

  Future<ChildProfile> createChild(ChildProfile profile) async {
    await _children.add(profile.toFirestore());
    return profile.copyWith();
  }

  Future<void> updateChild(ChildProfile profile) =>
      _children.doc(profile.id).update(profile.toFirestore());

  Future<void> deleteChild(String childId) =>
      _children.doc(childId).update({'isActive': false});

  Future<void> addScreenTime(String childId, int minutes) async {
    final expires = DateTime.now().add(Duration(minutes: minutes));
    await _children.doc(childId).update({
      'screenTimeExpiresAt': Timestamp.fromDate(expires),
    });
  }

  Future<void> consumeScreenTime(String childId) async {
    await _children.doc(childId).update({
      'screenTimeExpiresAt': null,
    });
  }

  // ---- Progress Records ----

  DocumentReference<Map<String, dynamic>> _progressDoc(String childId) =>
      _firestore.collection('progress').doc(childId);

  Future<ProgressRecord> getProgress(String childId) async {
    final doc = await _progressDoc(childId).get();
    if (!doc.exists) return ProgressRecord.initial(childId);
    return ProgressRecord.fromFirestore(doc);
  }

  Future<void> saveProgress(ProgressRecord record) async {
    await _progressDoc(record.childId)
        .set(record.toFirestore(), SetOptions(merge: true));
  }

  Stream<ProgressRecord> watchProgress(String childId) =>
      _progressDoc(childId).snapshots().map((doc) =>
          doc.exists ? ProgressRecord.fromFirestore(doc) : ProgressRecord.initial(childId));
}
