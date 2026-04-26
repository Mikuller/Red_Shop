import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:red_shop/firebase_options.dart';
import 'package:red_shop/models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.userChanges();

  Future<UserCredential> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final profile = await getUserProfile(credential.user!.uid);

    if (profile == null) {
      await signOut();
      throw StateError(
        'This account is missing a shop profile. Please contact the owner.',
      );
    }

    if (!profile.active) {
      await signOut();
      throw StateError('This account has been disabled by the owner.');
    }

    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<bool> ownerRegistrationAvailable() async {
    final query = await _db
        .collection('users')
        .where('role', isEqualTo: UserRole.owner.name)
        .limit(1)
        .get();

    return query.docs.isEmpty;
  }

  Future<UserCredential> registerInitialOwner({
    required String name,
    required String email,
    required String password,
  }) async {
    final canRegister = await ownerRegistrationAvailable();

    if (!canRegister) {
      throw StateError(
        'Owner setup is already complete. Use the login screen instead.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db
        .collection('users')
        .doc(credential.user!.uid)
        .set(
          UserModel(
            uid: credential.user!.uid,
            email: email.trim(),
            name: name.trim(),
            role: UserRole.owner,
            active: true,
            createdAt: DateTime.now(),
          ).toMap(),
        );

    return credential;
  }

  Future<void> createStaffAccount({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    required UserModel actor,
  }) async {
    if (actor.role != UserRole.owner) {
      throw StateError('Only owners can create staff accounts.');
    }

    FirebaseApp? secondaryApp;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'red-shop-staff-${DateTime.now().microsecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _db
          .collection('users')
          .doc(credential.user!.uid)
          .set(
            UserModel(
              uid: credential.user!.uid,
              email: email.trim(),
              name: name.trim(),
              role: role,
              active: true,
              createdAt: DateTime.now(),
            ).toMap(),
          );

      await secondaryAuth.signOut();
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
