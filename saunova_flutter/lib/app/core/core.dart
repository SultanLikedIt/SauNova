library;

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saunova/app/models/user_data.dart';
import 'package:saunova/app/services/api_service.dart';
import 'package:saunova/log/app_logger.dart';

import '../services/fire_service.dart';

part 'parts/core_data.dart';
part 'parts/core_auth.dart';
part 'parts/core_session.dart';

const _noChange = Object();

class Core extends Notifier<CoreState> {
  User? get firebaseUser => state.firebaseUser;
  UserData? get userData => state.userData;

  final _auth = FirebaseAuth.instance;

  @override
  CoreState build() {
    return CoreState(firebaseUser: _auth.currentUser, userData: null);
  }

  bool get _ensure => firebaseUser != null;

  initCore() async {
    if (!_ensure) return;
    try {
      final data = await ApiService.login();
      if (data == null) return;
      setState(userData: UserData.fromJson(data));
    } catch (error) {
      AppLogger.error('Core Init Error: $error');
    }
  }

  void setState({
    Object? userData = _noChange,
    Object? firebaseUser = _noChange,
  }) {
    if (userData == _noChange && firebaseUser == _noChange) {
      return;
    }
    state = CoreState.copyWith(
      userData: identical(userData, _noChange)
          ? state.userData
          : userData as UserData?,
      firebaseUser: identical(firebaseUser, _noChange)
          ? state.firebaseUser
          : firebaseUser as User?,
    );
  }
}

class CoreState {
  UserData? userData;
  User? firebaseUser;

  CoreState({this.userData, this.firebaseUser});

  CoreState.copyWith({UserData? userData, User? firebaseUser}) {
    this.userData = userData ?? this.userData;
    this.firebaseUser = firebaseUser ?? this.firebaseUser;
  }
}

final coreProvider = NotifierProvider<Core, CoreState>(Core.new);
