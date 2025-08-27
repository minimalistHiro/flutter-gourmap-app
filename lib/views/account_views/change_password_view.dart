 import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

 class ChangePasswordView extends StatefulWidget {
   const ChangePasswordView({super.key});

   @override
   State<ChangePasswordView> createState() => _ChangePasswordViewState();
 }

 class _ChangePasswordViewState extends State<ChangePasswordView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isSubmitting = false;
  
  // Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

   @override
   void dispose() {
     _currentController.dispose();
     _newController.dispose();
     _confirmController.dispose();
     super.dispose();
   }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text(
           'パスワードを変更',
           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
         ),
         centerTitle: true,
         backgroundColor: Colors.white,
         elevation: 0,
       ),
       body: SafeArea(
         child: SingleChildScrollView(
           padding: const EdgeInsets.all(16),
           child: Form(
             key: _formKey,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 _buildPasswordField(
                   label: '現在のパスワード',
                   controller: _currentController,
                   obscure: _obscureCurrent,
                   onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                   validator: (v) => (v == null || v.isEmpty) ? '現在のパスワードを入力してください' : null,
                 ),
                 const SizedBox(height: 16),
                 _buildPasswordField(
                   label: '新しいパスワード',
                   controller: _newController,
                   obscure: _obscureNew,
                   onToggle: () => setState(() => _obscureNew = !_obscureNew),
                   validator: _validateNewPassword,
                 ),
                 const SizedBox(height: 16),
                 _buildPasswordField(
                   label: '新しいパスワード（確認）',
                   controller: _confirmController,
                   obscure: _obscureConfirm,
                   onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                   validator: (v) {
                     if (v == null || v.isEmpty) return '確認用パスワードを入力してください';
                     if (v != _newController.text) return 'パスワードが一致しません';
                     return null;
                   },
                 ),
                 const SizedBox(height: 28),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: _isSubmitting ? null : _submit,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF1E88E5),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 14),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                     ),
                     child: _isSubmitting
                         ? const SizedBox(
                             width: 20,
                             height: 20,
                             child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                           )
                         : const Text('変更を保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   ),
                 ),
               ],
             ),
           ),
         ),
       ),
     );
   }

   String? _validateNewPassword(String? value) {
     if (value == null || value.isEmpty) return '新しいパスワードを入力してください';
     if (value.length < 8) return '8文字以上で入力してください';
     if (value == _currentController.text) return '現在のパスワードと異なるものを設定してください';
     return null;
   }

     Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 現在のパスワードで再認証
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentController.text,
        );
        
        await user.reauthenticateWithCredential(credential);
        
        // 新しいパスワードに変更
        await user.updatePassword(_newController.text);
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('パスワードを変更しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception('ユーザーが認証されていません');
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'パスワードの変更に失敗しました';
      if (e.toString().contains('wrong-password')) {
        errorMessage = '現在のパスワードが正しくありません';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'パスワードが弱すぎます';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

   Widget _buildPasswordField({
     required String label,
     required TextEditingController controller,
     required bool obscure,
     required VoidCallback onToggle,
     required String? Function(String?) validator,
   }) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
         const SizedBox(height: 6),
         TextFormField(
           controller: controller,
           obscureText: obscure,
           validator: validator,
           decoration: InputDecoration(
             filled: true,
             fillColor: Colors.white,
             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
             suffixIcon: IconButton(
               icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
               onPressed: onToggle,
             ),
             border: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12),
             ),
           ),
         ),
       ],
     );
   }
 }

