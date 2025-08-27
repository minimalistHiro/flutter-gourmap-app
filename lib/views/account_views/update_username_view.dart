import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateUsernameView extends StatefulWidget {
  final String username;

  const UpdateUsernameView({
    super.key,
    required this.username,
  });

  @override
  State<UpdateUsernameView> createState() => _UpdateUsernameViewState();
}

class _UpdateUsernameViewState extends State<UpdateUsernameView> {
  String editText = '';
  final FocusNode _focusNode = FocusNode();
  
  // Firebase関連
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    editText = widget.username;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get disabled {
    return editText == widget.username || editText.isEmpty;
  }

  Future<void> _updateUsername() async {
    if (disabled) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Firestoreのユーザードキュメントを更新
        await _firestore.collection('users').doc(user.uid).update({
          'username': editText,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザー名を変更しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception('ユーザーが認証されていません');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ユーザー名の変更に失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'ユーザー名を変更',
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
        child: Column(
          children: [
            const Spacer(),
            
            // ユーザー名入力フィールド
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ユーザー名',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: editText),
                    onChanged: (value) => setState(() => editText = value),
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'ストコポ太郎',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // 変更ボタン
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (disabled || _isSubmitting) ? null : _updateUsername,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (disabled || _isSubmitting) ? Colors.grey : Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'ユーザー名を変更',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            
            const Spacer(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
} 