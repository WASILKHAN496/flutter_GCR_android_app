import 'package:google_sign_in/google_sign_in.dart';

class GoogleLoginService {
  GoogleLoginService._internal();

  static final GoogleLoginService instance = GoogleLoginService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    return _googleSignIn.signIn();
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    return _googleSignIn.signInSilently();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}