part of '../core.dart';

extension CoreData on Core {
  String getRoute() {
    if (!_ensure) return '/login';

    if (userData != null) {
      if (userData!.onboardingCompleted) {
        return '/root';
      }
      return '/onboarding';
    }
    setState(userData: UserData.error());
    return '/no_connection';
  }

  Future<void> reload() async {
    if (!_ensure) return;
    final data = await ApiService.login();
    if (data != null) {
      AppLogger.info('User data reloaded');
      setState(userData: UserData.fromJson(data));
    }
  }

  Future<bool> saveUserProfile(
    int age,
    String gender,
    int height,
    int weight,
    List<String> goals,
  ) async {
    if (!_ensure) return false;
    final data = await ApiService.finishSetup(
      gender,
      height,
      weight,
      age,
      goals,
    );
    if (data != null) {
      setState(userData: UserData.fromJson(data));
      return true;
    }
    return false;
  }

  Future<void> updateImage(File imageFile) async {
    if (!_ensure) return;
    final imageUrl = await FireService.uploadImage(
      imageFile,
      firebaseUser!.uid,
    );
    if (imageUrl != null) {
      ApiService.setProfileImage(imageUrl);
      setState(userData: userData!.copyWith(image: imageUrl));
    }
  }

  Future<void> deleteImage() async {
    if (!_ensure) return;
    ApiService.setProfileImage(null);
    await FireService.deleteImage(firebaseUser!.uid);
    setState(userData: userData!.copyWith(image: null));
  }
}
