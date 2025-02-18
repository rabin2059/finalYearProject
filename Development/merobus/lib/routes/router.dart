import 'package:go_router/go_router.dart';
import 'package:merobus/Screens/Authentication/get_started.dart';
import 'package:merobus/Screens/Authentication/signin.dart';
import 'package:merobus/Screens/Authentication/signup.dart';
import 'package:merobus/navigation/navigation.dart';

// final prefs = SharedPreferences;
// final int role = prefs.getInt('userRole');
final goRouter = GoRouter(initialLocation: '/', routes: <RouteBase>[
  GoRoute(
      path: '/', name: '/', builder: (context, state) => const GetStarted()),
  GoRoute(
      path: '/signup',
      name: '/signup',
      builder: (context, state) => const SignUp()),
  GoRoute(
      path: '/login',
      name: '/login',
      builder: (context, state) => const SignIn()),
  GoRoute(
    name: 'navigation',
    path: '/nav',
    builder: (context, state) {
      final int role = state.extra as int;
      return Navigation(dept: role);
    },
  ),
]);
