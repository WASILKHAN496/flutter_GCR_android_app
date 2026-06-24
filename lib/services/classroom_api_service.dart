import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/classroom/v1.dart' as classroom;
import 'package:shared_preferences/shared_preferences.dart';
class GoogleLoginService {
  GoogleLoginService._internal();

  static final GoogleLoginService instance = GoogleLoginService._internal();

  static const String webClientId =
      '251944777475-kietn94gdpodidfbrl8qttft1u8eu5dt.apps.googleusercontent.com';

  static const List<String> classroomScopes = <String>[
    classroom.ClassroomApi.classroomCoursesReadonlyScope,
    classroom.ClassroomApi.classroomCourseworkMeReadonlyScope,
    classroom.ClassroomApi.classroomStudentSubmissionsMeReadonlyScope,
    classroom.ClassroomApi.classroomProfileEmailsScope,
    classroom.ClassroomApi.classroomProfilePhotosScope,
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: classroomScopes,
    serverClientId: webClientId,
  );

  classroom.ClassroomApi? _classroomApi;

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();

    if (account == null) {
      return null;
    }

    await getClassroomApi();

    return account;
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently();

    if (account != null) {
      await getClassroomApi();
    }

    return account;
  }

  Future<classroom.ClassroomApi> getClassroomApi() async {
    if (_classroomApi != null) {
      return _classroomApi!;
    }

    final client = await _googleSignIn.authenticatedClient();

    if (client == null) {
      throw Exception('Google API client not available. Please login again.');
    }

    _classroomApi = classroom.ClassroomApi(client);

    return _classroomApi!;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _classroomApi = null;
  }
}