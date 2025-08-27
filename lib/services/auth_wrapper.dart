import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../views/entry_views/welcome_view.dart';
import '../views/content_view.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 認証状態をチェック中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1E88E5),
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }
        
        // ユーザーがログインしている場合
        if (snapshot.hasData && snapshot.data != null) {
          return const ContentView();
        }
        
        // ユーザーがログインしていない場合
        return const WelcomeView();
      },
    );
  }
} 