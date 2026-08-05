import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Future<AuthResult> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw const AuthCancelledException();

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return _toAuthResult(userCredential.user!);
  }

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(AuthResult result) onAutoVerified,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onFailed,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        final userCredential = await _auth.signInWithCredential(credential);
        onAutoVerified(_toAuthResult(userCredential.user!));
      },
      verificationFailed: (e) => onFailed(e.message ?? 'Verification failed'),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<AuthResult> verifyOtp({required String verificationId, required String smsCode}) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return _toAuthResult(userCredential.user!);
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  AuthResult _toAuthResult(User user) => AuthResult(
        uid: user.uid,
        phoneNumber: user.phoneNumber,
        displayName: user.displayName,
        email: user.email,
      );
}
