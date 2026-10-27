import 'user_profile.dart';

class AuthState {
  final bool isAuthenticated;
  final UserProfile? user;
  final bool isGuest;

  const AuthState({
    required this.isAuthenticated,
    this.user,
    this.isGuest = false,
  });

  bool get isLoggedIn => isAuthenticated && user != null;

  const AuthState.unauthenticated()
      : isAuthenticated = false,
        user = null,
        isGuest = false;

  const AuthState.guest()
      : isAuthenticated = false,
        user = null,
        isGuest = true;

  const AuthState.authenticated(UserProfile user)
      : isAuthenticated = true,
        user = user,
        isGuest = false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          isAuthenticated == other.isAuthenticated &&
          user == other.user &&
          isGuest == other.isGuest;

  @override
  int get hashCode => Object.hash(isAuthenticated, user, isGuest);

  @override
  String toString() =>
      'AuthState(isAuthenticated: $isAuthenticated, user: ${user?.fullName}, isGuest: $isGuest)';
}
