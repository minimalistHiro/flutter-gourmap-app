import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackView extends StatefulWidget {
  const FeedbackView({super.key});

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _selectedCategory = 'バグ報告';
  String _selectedPriority = '通常';
  bool _isLoading = false;
  
  final List<String> _categories = [
    'バグ報告',
    '機能要望',
    'UI/UX改善',
    'パフォーマンス',
    'その他',
  ];
  
  final List<String> _priorities = [
    '低',
    '通常', 
    '高',
    '緊急',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('タイトルを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('フィードバック内容を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ログインが必要です');
      }

      // ユーザー情報を取得
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final username = userData['username'] ?? 'ユーザー';

      // フィードバックを通知として保存
      await _firestore.collection('notifications').add({
        'title': '[フィードバック] ${_titleController.text.trim()}',
        'content': _feedbackController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'type': 'feedback', // フィードバック識別用
        'userId': user.uid,
        'username': username,
        'userEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'publishedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isPublished': true,
        'readCount': 0,
        'totalViews': 0,
        'isOwnerOnly': true, // オーナーのみ表示
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('フィードバックを送信しました。ご意見ありがとうございます！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // フォームをクリア
        _titleController.clear();
        _feedbackController.clear();
        setState(() {
          _selectedCategory = 'バグ報告';
          _selectedPriority = '通常';
        });

        // 画面を閉じる
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('フィードバック送信エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('フィードバックの送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'フィードバック',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 説明テキスト
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.feedback,
                        color: Color(0xFFFF6B35),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ご意見・ご要望をお聞かせください',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'アプリの改善に向けて、バグ報告や機能要望などのフィードバックをお送りください。お送りいただいた内容は開発チームが確認し、今後のアップデートに活用させていただきます。',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // タイトル入力
            _buildTextField(
              label: 'タイトル *',
              hint: '例：ポイント画面でエラーが発生する',
              controller: _titleController,
            ),

            const SizedBox(height: 20),

            // カテゴリ選択
            _buildDropdownField(
              label: 'カテゴリ',
              value: _selectedCategory,
              items: _categories,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            // 優先度選択
            _buildDropdownField(
              label: '優先度',
              value: _selectedPriority,
              items: _priorities,
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            // フィードバック内容
            _buildTextAreaField(
              label: 'フィードバック内容 *',
              hint: '詳細をお聞かせください...\n\n例：\n・どのような操作をした時に発生したか\n・期待していた動作\n・実際に起こった問題',
              controller: _feedbackController,
            ),

            const SizedBox(height: 30),

            // 送信ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'フィードバックを送信',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // 注意事項
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '注意事項',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• 個人情報やパスワードなどの機密情報は入力しないでください\n• 緊急の問題については、アプリ内のお問い合わせからご連絡ください\n• すべてのフィードバックにお返事できない場合がございます',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
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
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF6B35)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({
    required String label,
    required String hint,
    required TextEditingController controller,
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
          maxLines: 8,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF6B35)),
            ),
            contentPadding: const EdgeInsets.all(12),
            filled: true,
            fillColor: Colors.white,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              onChanged: onChanged,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}