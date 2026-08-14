import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  /// Sends an OTP to [phoneNumber] (must be in E.164 format, e.g. "+919876543210").
  /// [onCodeSent] fires once Firebase has dispatched the SMS, giving you the
  /// verificationId needed to confirm the code the user enters.
  /// [onVerificationFailed] fires on invalid number / quota / network errors.
  /// [onAutoVerified] fires only on Android devices that can auto-detect the
  /// SMS and sign in without the user typing anything.
  static Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onVerificationFailed,
    required void Function(UserCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final result = await _auth.signInWithCredential(credential);
        onAutoVerified(result);
      },
      verificationFailed: (FirebaseAuthException e) {
        onVerificationFailed(e.message ?? "Verification failed");
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Confirms the 6-digit code the user typed against the given verificationId.
  static Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  static Future<void> signOut() => _auth.signOut();
}