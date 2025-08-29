import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'services/auth_wrapper.dart';
import 'services/firebase_auth_service.dart';
import 'views/content_view.dart';
import 'views/entry_views/welcome_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('=== Firebase初期化開始 ===');
    print('プラットフォーム: ${kIsWeb ? 'Web' : 'Mobile'}');
    
    // Firebase初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print('Firebase初期化完了');
    
    // プラットフォームに応じてFirebase機能を初期化
    if (!kIsWeb) {
      // モバイルプラットフォームのみ
      try {
        print('モバイルプラットフォーム用Firebase機能初期化開始...');
        // Firebase Analytics設定
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
        
        // Firebase Messaging設定
        await FirebaseMessaging.instance.requestPermission();
        
        // Firebase Crashlytics設定
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        
        print('モバイルプラットフォーム用Firebase機能初期化完了');
      } catch (e) {
        if (kDebugMode) {
          print('Firebase機能の初期化でエラーが発生しました: $e');
        }
      }
    } else {
      // Webプラットフォーム
      try {
        print('Webプラットフォーム用Firebase機能初期化開始...');
        // Web用のFirebase Analytics設定
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
        
        // Web用のFirebase Auth設定
        print('Firebase Auth初期化中...');
        await FirebaseAuth.instance.authStateChanges().first;
        
        print('Web用Firebase初期化が完了しました');
      } catch (e) {
        if (kDebugMode) {
          print('Web用Firebase初期化でエラーが発生しました: $e');
        }
      }
    }
    
    // 既存ユーザーに店舗アカウントステータスを追加
    try {
      print('既存ユーザーへの店舗アカウントステータス追加処理を開始...');
      final authService = FirebaseAuthService();
      await authService.addStoreOwnerStatusToExistingUsers();
      print('既存ユーザーへの店舗アカウントステータス追加処理が完了しました');
    } catch (e) {
      if (kDebugMode) {
        print('既存ユーザーへの店舗アカウントステータス追加処理でエラーが発生しました: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase初期化でエラーが発生しました: $e');
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GourMap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const ContentView(),
        '/welcome': (context) => const WelcomeView(),
      },
      navigatorObservers: kIsWeb ? [] : [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
    );
  }
}
