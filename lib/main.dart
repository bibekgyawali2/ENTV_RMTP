import 'package:flutter/material.dart';
import 'package:tv_app/pages/setup_page.dart';
import 'package:tv_app/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RTMP Streamer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SetupPage(),
    );
  }
}
