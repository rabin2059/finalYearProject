import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'Screens/Authentication/get_started.dart';
import 'providers/map_provider.dart';
import 'Screens/bus/bus_details_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: GoogleFonts.roboto().fontFamily,
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white, // Set background to white
          ),
          home: child,
          routes: {
            '/bus-details': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return BusDetailsScreen(
                bus: args['bus'],
                routePoints: args['routePoints'],
                userLocation: args['userLocation'],
              );
            },
          },
        );
      },
      child: const GetStarted(),
    );
  }
}
