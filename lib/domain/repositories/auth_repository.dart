/// The signed-in identity, regardless of which path (Google or phone)
/// produced it.
class AuthResult {
  const AuthResult({required this.uid, this.phoneNumber, this.displayName, this.email});

  final String uid;
  final String? phoneNumber;
  final String? displayName;
  final String? email;
}

/// Thrown when the person backs out of a sign-in flow (e.g. dismisses the
/// Google account picker) — not an error, just "try again".
class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

/// Authentication for the resolved onboarding flow (see the implementation
/// plan's "Resolved conflict: sign-up method"):
/// - Google path: [signInWithGoogle] only — the phone number collected on
///   A3 afterward is a plain contact field, never sent through [sendOtp].
/// - Phone path: [sendOtp] then [verifyOtp] — here the phone number IS the
///   identity being verified (FR-3.1.2).
abstract interface class AuthRepository {
  Future<AuthResult> signInWithGoogle();

  /// Starts phone verification for [phoneNumber] (E.164 format, e.g.
  /// "+923001234567"). Android's SMS Retriever may auto-complete
  /// verification with zero code entry — FR-3.1.2's "one-tap OTP
  /// confirmation" — in which case [onAutoVerified] fires directly and the
  /// UI should treat it exactly like a successful [verifyOtp]. Otherwise
  /// [onCodeSent] provides the verificationId for [verifyOtp].
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(AuthResult result) onAutoVerified,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onFailed,
  });

  Future<AuthResult> verifyOtp({required String verificationId, required String smsCode});

  Future<void> signOut();
}
