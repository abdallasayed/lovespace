import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/config/firebase_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // إعدادات النظام
  await _setupSystemUI();
  
  // تهيئة Firebase
  await _initializeFirebase();
  
  // إعدادات التطبيق
  await _setupAppConfig();
  
  runApp(const MyApp());
}

// دالة منفصلة لتهيئة Firebase
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.options,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('🔥 خطأ في تهيئة Firebase: $e');
    rethrow;
  }
}

// دالة لإعدادات النظام
Future<void> _setupSystemUI() async {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
}

// دالة لإعدادات التطبيق
Future<void> _setupAppConfig() async {
  // إعداد الترجمة العربية لـ timeago
  timeago.setLocaleMessages('ar', timeago.ArMessages());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عشاق',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      locale: const Locale('ar', 'AE'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const AuthGate(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.pink,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      textTheme: GoogleFonts.cairoTextTheme(
        ThemeData.light().textTheme,
      ),
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE11D48),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
