import 'dart:io';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/screens/home_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/widgets/download_overlay.dart';
import 'src/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Constants.supabaseUrl,
    anonKey: Constants.supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTV Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      builder: (context, child) => DownloadOverlay(
        child: child ?? const SizedBox.shrink(),
      ),
      home: _loggedIn() ? const HomeScreen() : const LoginScreen(),
    );
  }

  bool _loggedIn() {
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return true;
    }
  }
}
