import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merobus/routes/global.dart';
import 'package:merobus/user/Driver/home/presentation/driver_home_screen.dart';

import '../../core/role.dart';
import '../authentication/login/providers/auth_provider.dart';
import 'admin_navigation.dart';
import 'driver_navigation.dart';
import 'user_driver_navigation.dart';
import 'user_navigation.dart';

class Navigation extends ConsumerWidget {
  const Navigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.currentRole == UserRole.ADMIN) {
      return const AdminNavigation();
    } else if (authState.currentRole == UserRole.DRIVER) {
      return const DriverNavigation();
    } else if (authState.currentRole == UserRole.DRIVERUSER) {
      return const UserDriverNavigation();
    } else {
      return const UserNavigation();
    }
  }
}
