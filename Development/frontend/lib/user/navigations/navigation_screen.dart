import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/user/navigations/admin_navigation.dart';
import 'package:frontend/user/navigations/driver_navigation.dart';
import 'package:frontend/user/navigations/user_navigation.dart';

import '../../core/role.dart';
import '../authentication/login/providers/auth_provider.dart';

class Navigation extends ConsumerWidget {
  const Navigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.currentRole == UserRole.ADMIN) {
      return const AdminNavigation();
    } else if (authState.currentRole == UserRole.DRIVER) {
      return const DriverNavigation();
    } else {
      return const UserNavigation();
    }
  }
}