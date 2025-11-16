part of '../core.dart';

extension CoreAuth on Core {
  Future<void> emailSignIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final data = await ApiService.login();
      if (data == null) throw 'Failed to fetch user profile';
      setState(
        firebaseUser: credential.user,
        userData: UserData.fromJson(data),
      );
    } catch (error) {
      AppLogger.error('Email Sign In Error: $error');
    }
  }

  Future<void> emailSignUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) return;

      final data = await ApiService.signUp(email, null);
      if (data == null) throw 'Failed to create user profile';

      setState(firebaseUser: firebaseUser, userData: UserData.fromJson(data));
    } catch (error) {
      AppLogger.error('Email Sign Up Error: $error');
    }
  }

  Future<void> continueWithGoogle(OAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw 'Google Sign-In failed';

      if (firebaseUser.email == null) {
        throw 'Google Sign-In failed: No email found';
      }

      final data = await ApiService.signUp(
        firebaseUser.email!,
        firebaseUser.photoURL,
      );
      if (data == null) throw 'Failed to create user profile';
      AppLogger.info(data);
      setState(firebaseUser: firebaseUser, userData: UserData.fromJson(data));
    } catch (error) {
      AppLogger.error('Google Sign-In Error: $error');
    }
  }
}
