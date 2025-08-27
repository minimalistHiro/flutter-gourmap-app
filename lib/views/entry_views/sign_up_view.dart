import 'package:flutter/material.dart';
import 'email_sign_up_view.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
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
            
            // Apple登録ボタン
            _buildSignUpButton(
              title: 'Appleで登録',
              icon: Icons.apple,
              backgroundColor: Colors.black,
              onTap: () {
                // Apple登録処理（後で実装）
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appleで登録')),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Google登録ボタン
            _buildSignUpButton(
              title: 'Googleで登録',
              icon: Icons.g_mobiledata,
              backgroundColor: Colors.red,
              onTap: () {
                // Google登録処理（後で実装）
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Googleで登録')),
                );
              },
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
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpButton({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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