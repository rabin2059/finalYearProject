import 'package:merobus/models/user_model.dart';

class UserState {
  final bool isLoggedIn;
  final User? user;

  UserState({required this.isLoggedIn, required this.user});

  UserState copyWith({bool? isLoggedIn, User? user}) {
    return UserState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn, user: user ?? this.user);
  }
}
