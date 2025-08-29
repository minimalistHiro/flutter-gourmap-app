import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../content_view.dart';
import '../../services/firebase_auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool isShowPassword = false;
  bool isLoading = false;
  String email = '';
  String password = '';
  final FocusNode _focusNode = FocusNode();
  
  // TextEditingControllerを適切に管理
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  
  // Firebase Auth Service
  final FirebaseAuthService _authService = FirebaseAuthService();

  bool get disabled {
    return email.isEmpty || password.isEmpty;
  }

  // ログイン処理
  Future<void> _signIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('=== ログイン開始 ===');
      print('Email: $email');
      
      // Firebase認証でログイン
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('ログイン成功');
      
      // 成功メッセージと自動遷移
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインしました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 少し待ってからホーム画面に自動遷移
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          // ログイン画面を完全に置き換えてコンテンツ画面に遷移
          // これにより、戻るボタンでログイン画面に戻ることができなくなる
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const ContentView(),
            ),
            (route) => false, // すべての画面を削除
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print('=== ログインエラー発生 ===');
      print('Error Code: ${e.code}');
      print('Error Message: ${e.message}');
      print('Error Details: ${e.toString()}');
      
      String errorTitle = 'ログインエラー';
      String errorMessage = 'ログインに失敗しました。';
      
      switch (e.code) {
        case 'user-not-found':
          errorTitle = 'アカウントが見つかりません';
          errorMessage = 'このメールアドレスで登録されたアカウントが見つかりません。\n\n対処方法：\n• メールアドレスが正しく入力されているか確認してください\n• 新規会員登録を行ってください\n• 大文字・小文字の違いがないか確認してください';
          break;
        case 'wrong-password':
          errorTitle = 'パスワードが正しくありません';
          errorMessage = '入力されたパスワードが正しくありません。\n\n対処方法：\n• パスワードを再入力してください\n• 大文字・小文字の違いがないか確認してください\n• スペースや特殊文字が含まれていないか確認してください\n• パスワードを忘れた場合は、パスワードリセットを行ってください';
          break;
        case 'invalid-email':
          errorTitle = '無効なメールアドレスです';
          errorMessage = '入力されたメールアドレスの形式が正しくありません。\n\n正しい形式：\n• example@domain.com\n• user.name@company.co.jp\n\n確認事項：\n• @マークが含まれているか\n• ドメイン部分が正しいか\n• スペースや特殊文字が含まれていないか';
          break;
        case 'user-disabled':
          errorTitle = 'アカウントが無効です';
          errorMessage = 'このアカウントは管理者によって無効にされています。\n\n対処方法：\n• 管理者にお問い合わせください\n• 別のアカウントでログインしてください';
          break;
        case 'too-many-requests':
          errorTitle = 'リクエストが多すぎます';
          errorMessage = '短時間に多くのログイン試行が行われました。\n\n対処方法：\n• しばらく時間をおいてから再度お試しください\n• パスワードが正しいか確認してください\n• 必要に応じてパスワードリセットを行ってください';
          break;
        case 'invalid-credential':
          errorTitle = '認証情報が無効です';
          errorMessage = 'メールアドレスまたはパスワードが正しくありません。\n\n対処方法：\n• メールアドレスとパスワードを再確認してください\n• 大文字・小文字の違いがないか確認してください\n• アカウントが正しく作成されているか確認してください';
          break;
        case 'operation-not-allowed':
          errorTitle = 'ログインが無効です';
          errorMessage = 'このアプリではメール・パスワードによるログインが設定されていません。\n\n開発者にお問い合わせください。';
          break;
        default:
          errorTitle = '認証エラー';
          errorMessage = 'ログイン中にエラーが発生しました。\n\nエラーコード: ${e.code}\nエラーメッセージ: ${e.message}\n\nしばらく時間をおいてから再度お試しください。\n問題が解決しない場合は、開発者にお問い合わせください。';
      }
      
      if (mounted) {
        _showErrorDialog(errorTitle, errorMessage);
      }
    } catch (e) {
      print('=== 予期しないエラー発生 ===');
      print('Error: $e');
      print('Error Type: ${e.runtimeType}');
      
      if (mounted) {
        _showErrorDialog(
          '予期しないエラー',
          'ログイン中に予期しないエラーが発生しました。\n\nエラー詳細: $e\n\nしばらく時間をおいてから再度お試しください。\n問題が解決しない場合は、開発者にお問い合わせください。'
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
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
          ),
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

  // Googleサインイン
  Future<void> _signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Googleアカウントでログインしました'),
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
          'Googleログインエラー',
          'Googleアカウントでのログインに失敗しました。\n\nエラー詳細: $e\n\nしばらく時間をおいてから再度お試しください。'
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

  // Apple Sign In
  Future<void> _signInWithApple() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithApple();
      
      if (userCredential != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple IDでログインしました'),
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
          'Apple IDログインエラー',
          'Apple IDでのログインに失敗しました。\n\nエラー詳細: $e\n\nしばらく時間をおいてから再度お試しください。'
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

  @override
  void initState() {
    super.initState();
    // TextEditingControllerを初期化
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ログイン',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // タップでキーボードを閉じる
          _focusNode.unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // ロゴ・タイトル
              _buildHeader(),
              
              const SizedBox(height: 30),
              
              // 区切り線
              _buildDivider(),
              
              const SizedBox(height: 40),
              
              // メールアドレス入力
              _buildTextField(
                label: 'メールアドレス',
                controller: _emailController,
                onChanged: (value) => setState(() => email = value),
                keyboardType: TextInputType.emailAddress,
                focusNode: _focusNode,
              ),
              
              const SizedBox(height: 20),
              
              // パスワード入力
              _buildPasswordField(
                label: 'パスワード',
                controller: _passwordController,
                onChanged: (value) => setState(() => password = value),
                isShowPassword: isShowPassword,
                onTogglePassword: () => setState(() => isShowPassword = !isShowPassword),
              ),
              
              const SizedBox(height: 30),
              
              // ログインボタン
              _buildLoginButton(),
              
              const SizedBox(height: 20),
              
              // パスワードを忘れた方
              _buildForgotPassword(),
              
              const SizedBox(height: 30),
              
              // 区切り線
              _buildDivider(),
              
              const SizedBox(height: 20),
              
              // Googleサインインボタン
              _buildSocialButton(
                text: 'Googleでログイン',
                icon: Icons.account_circle,
                backgroundColor: Colors.white,
                textColor: Colors.black87,
                borderColor: Colors.grey[300]!,
                onPressed: isLoading ? null : _signInWithGoogle,
              ),
              
              const SizedBox(height: 15),
              
              // Apple Sign Inボタン（Web環境では無効）
              _buildSocialButton(
                text: 'Apple IDでログイン（準備中）',
                icon: Icons.apple,
                backgroundColor: Colors.grey,
                textColor: Colors.white,
                borderColor: Colors.grey,
                onPressed: null, // Web環境では無効化
              ),
              
              const SizedBox(height: 10),
              
              // 注意書き
              Text(
                '※ソーシャルログインは現在準備中です',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/gourmap_icon.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'GourMap',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'アカウントにログイン',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }





  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'または',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (disabled || isLoading) ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? Colors.grey : const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: disabled ? 0 : 2,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'メールアドレスでログイン',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('パスワードリセット画面')),
        );
      },
      child: const Text(
        'パスワードを忘れた方はこちら',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF1E88E5),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: textColor),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          focusNode: focusNode,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    required bool isShowPassword,
    required VoidCallback onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: !isShowPassword,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: Icon(
                isShowPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: onTogglePassword,
            ),
          ),
        ),
      ],
    );
  }
} 