import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/features/profile/presentation/profile_screen.dart';
import 'package:frontend/features/role%20change/presentation/role_change_screen.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        // return MaterialApp.router(
        //   debugShowCheckedModeBanner: false,
        //   theme: ThemeData(
        //     fontFamily: GoogleFonts.roboto().fontFamily,
        //     useMaterial3: true,
        //     scaffoldBackgroundColor: Colors.white, // Set background to white
        //   ),
        //   routerDelegate: goRouter.routerDelegate,
        //   routeInformationParser: goRouter.routeInformationParser,
        //   routeInformationProvider: goRouter.routeInformationProvider,
        // );
        return MaterialApp(
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white, // Set background to white
          ),
          debugShowCheckedModeBanner: false,
          home: RoleChangeScreen(),
        );
      },
    );
  }
}
