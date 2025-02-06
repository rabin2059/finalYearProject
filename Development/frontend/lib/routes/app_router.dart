import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/profile/presentation/profile_screen.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/providers/auth_provider.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/navigations/navigation_screen.dart';
import '../get_started_screen.dart';

final goRouter = GoRouter(initialLocation: '/', routes: <RouteBase>[
  GoRoute(
      path: '/', name: '/', builder: (context, state) => const GetStartedScreen()),
  GoRoute(
      path: '/signup',
      name: '/signup',
      builder: (context, state) => const LoginScreen
      ()),
  GoRoute(
      path: '/login',
      name: '/login',
      builder: (context, state) => const LoginScreen()),
  GoRoute(
    name: '/navigation',
    path: '/navigation',
    builder: (context, state) => Navigation()),
  GoRoute(
    name: '/profile',
    path: '/profile',
    builder: (context, state) => ProfileScreen()),
]);
