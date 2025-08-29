import 'package:flutter/material.dart';
import 'email_sign_up_view.dart';
import '../../services/firebase_auth_service.dart';
import '../content_view.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  bool isLoading = false;
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Googleサインアップ
  Future<void> _signUpWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Googleアカウントで登録しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ContentView()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Google登録エラー',
          'Googleアカウントでの登録に失敗しました。\n\nエラー詳細: $e\n\nしばらく時間をおいてから再度お試しください。'
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Apple Sign Up
  Future<void> _signUpWithApple() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithApple();
      
      if (userCredential != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple IDで登録しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ContentView()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Apple ID登録エラー',
          'Apple IDでの登録に失敗しました。\n\nエラー詳細: $e\n\nしばらく時間をおいてから再度お試しください。'
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // エラーダイアログを表示
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '新規会員登録',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 50),
            
            // 登録方法選択
            const Text(
              '登録方法を選択してください',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Apple登録ボタン（Web環境では無効）
            _buildSignUpButton(
              title: 'Appleで登録（準備中）',
              icon: Icons.apple,
              backgroundColor: Colors.grey,
              onTap: null, // Web環境では無効化
            ),
            
            const SizedBox(height: 20),
            
            // Google登録ボタン
            _buildSignUpButton(
              title: 'Googleで登録',
              icon: Icons.account_circle,
              backgroundColor: Colors.red,
              onTap: isLoading ? null : _signUpWithGoogle,
            ),
            
            const SizedBox(height: 20),
            
            // メールアドレス登録ボタン
            _buildSignUpButton(
              title: 'メールアドレスで登録',
              icon: Icons.email,
              backgroundColor: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EmailSignUpView(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // 注意書き
            Text(
              '※ソーシャル登録は現在準備中です\nメールアドレスでの登録をお勧めします',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpButton({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: onTap == null ? backgroundColor.withOpacity(0.5) : backgroundColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading && (title.contains('Apple') || title.contains('Google')))
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 