import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/sender/sender_screen.dart';
import 'features/receiver/receiver_screen.dart';
import 'features/result/transfer_result_screen.dart';
import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';

class QRLinkApp extends StatelessWidget {
  const QRLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/send': (context) => const SenderScreen(),
        '/receive': (context) => const ReceiverScreen(),
        '/result': (context) => const TransferResultScreen(),
        '/history': (context) => const HistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
