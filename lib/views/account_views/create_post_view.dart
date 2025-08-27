import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'create_store_view.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'お知らせ';
  String? _selectedStoreId;
  String _selectedStoreName = '';
  bool _isLoading = false;
  bool _isLoadingStores = true;
  List<Map<String, dynamic>> _userStores = [];
  
  // 写真関連
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Uint8List> _selectedImages = [];
  final int _maxImages = 5;
  
  final List<String> _categories = [
    'お知らせ',
    'イベント',
    'キャンペーン',
    'メニュー',
    'その他',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserStores();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ユーザーが作成した店舗を読み込む
  Future<void> _loadUserStores() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('店舗読み込み開始: ユーザーID = ${user.uid}');

      // まず、storesコレクションの構造を確認
      final storesSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .get();

      print('全店舗数: ${storesSnapshot.docs.length}');
      
      // 各店舗のデータを確認
      for (final doc in storesSnapshot.docs) {
        final data = doc.data();
        print('店舗ID: ${doc.id}, データ: $data');
      }

      // createdByフィールドでフィルタリング
      final userStores = storesSnapshot.docs.where((doc) {
        final data = doc.data();
        final createdBy = data['createdBy'];
        print('店舗 ${doc.id}: createdBy = $createdBy, ユーザーID = ${user.uid}');
        return createdBy == user.uid;
      }).toList();

      print('ユーザーの店舗数: ${userStores.length}');

      if (mounted) {
        setState(() {
          _userStores = userStores
              .map((doc) => {
                    'storeId': doc.id,
                    'storeName': doc.data()['name'] ?? '店舗名なし',
                  })
              .toList();
          _isLoadingStores = false;
        });
      }
    } catch (e) {
      print('店舗読み込みエラー: $e');
      if (mounted) {
        setState(() {
          _isLoadingStores = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗情報の読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 写真を選択
  Future<void> _pickImages() async {
    try {
      if (_selectedImages.length >= _maxImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('写真は最大${_maxImages}枚まで選択できます'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _selectedImages.add(imageBytes);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('写真の選択に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 写真を削除
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // 投稿IDを生成
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;
      
      // 店舗が選択されているかチェック
      if (_selectedStoreId == null || _selectedStoreName.isEmpty) {
        throw Exception('店舗を選択してください');
      }

      // 画像をFirebase Storageに保存（失敗時はBase64でフォールバック）
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        print('画像保存開始: ${_selectedImages.length}枚');
        
        for (int i = 0; i < _selectedImages.length; i++) {
          final imageBytes = _selectedImages[i];
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final imageFileName = 'posts/$postId/image_${i}_$timestamp.jpg';
          
          bool storageSuccess = false;
          
          // 方法1: Firebase Storageでの保存を試行
          try {
            print('方法1: Firebase Storage保存試行: $imageFileName');
            final ref = _storage.ref().child(imageFileName);
            
            // メタデータを設定
            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'postId': postId,
                'uploadedBy': user.uid,
                'uploadedAt': timestamp.toString(),
              },
            );
            
            final uploadTask = ref.putData(imageBytes, metadata);
            final snapshot = await uploadTask;
            final downloadUrl = await snapshot.ref.getDownloadURL();
            
            imageUrls.add(downloadUrl);
            storageSuccess = true;
            print('方法1成功: Firebase Storage保存完了 - $downloadUrl');
          } catch (e) {
            print('方法1でエラー: $e');
          }
          
          // 方法2: Firebase Storageが失敗した場合、Base64でフォールバック
          if (!storageSuccess) {
            try {
              print('方法2: Base64フォールバック開始');
              final base64String = base64Encode(imageBytes);
              final base64Url = 'data:image/jpeg;base64,$base64String';
              imageUrls.add(base64Url);
              print('方法2成功: Base64フォールバック保存完了');
            } catch (base64Error) {
              print('方法2でエラー: $base64Error');
              // 最後の手段として、エラーメッセージを含むプレースホルダーを追加
              imageUrls.add('error:image_failed_to_load');
              print('画像保存完全失敗: プレースホルダーを追加');
            }
          }
        }
      }
      
      print('最終的な画像URL数: ${imageUrls.length}');
      
      // 保存方法の統計を計算
      int firebaseStorageCount = 0;
      int base64Count = 0;
      int errorCount = 0;
      
      for (String url in imageUrls) {
        if (url.startsWith('https://firebasestorage.googleapis.com')) {
          firebaseStorageCount++;
        } else if (url.startsWith('data:image/jpeg;base64,')) {
          base64Count++;
        } else if (url.startsWith('error:')) {
          errorCount++;
        }
      }
      
      print('保存方法統計: Firebase Storage = $firebaseStorageCount, Base64 = $base64Count, エラー = $errorCount');

      // 店舗のアイコン画像URLを取得
      String? storeIconImageUrl;
      try {
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(_selectedStoreId)
            .get();
        
        if (storeDoc.exists) {
          final storeData = storeDoc.data()!;
          storeIconImageUrl = storeData['iconImageUrl'];
        }
      } catch (e) {
        print('店舗アイコン画像URL取得エラー: $e');
      }

      // Firestoreに投稿情報を保存
      await FirebaseFirestore.instance.collection('posts').doc(postId).set({
        'postId': postId,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'storeId': _selectedStoreId,
        'storeName': _selectedStoreName,
        'storeIconImageUrl': storeIconImageUrl, // 店舗アイコン画像URLを追加
        'category': _selectedCategory,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isPublished': true,
        'likes': 0,
        'views': 0,
        'comments': [],
        'imageUrls': imageUrls,
        'imageCount': imageUrls.length,
      });

      if (mounted) {
        // 成功ダイアログを表示
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '投稿作成完了',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '「${_titleController.text.trim()}」が正常に投稿されました！',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // 前の画面に戻る
                  },
                  child: const Text('OK'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('投稿作成に失敗しました: $e'),
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
          '新規投稿作成',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.post_add,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '新しい投稿を作成',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'お客様に情報をお届けしましょう',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // カテゴリ
              _buildCategoryDropdown(),
              
              const SizedBox(height: 20),
              
              // 店舗選択
              _buildStoreDropdown(),
              
              const SizedBox(height: 20),
              
              // タイトル
              _buildInputField(
                controller: _titleController,
                label: 'タイトル *',
                hint: '例：新メニュー登場！',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  if (value.trim().length < 3) {
                    return 'タイトルは3文字以上で入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // 写真選択
              _buildImageSection(),
              
              const SizedBox(height: 20),
              
              // 内容
              _buildInputField(
                controller: _contentController,
                label: '投稿内容 *',
                hint: '投稿の詳細内容を入力してください',
                icon: Icons.description,
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '投稿内容を入力してください';
                  }
                  if (value.trim().length < 10) {
                    return '投稿内容は10文字以上で入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // 作成ボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '投稿を作成',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 注意事項
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '投稿は即座に公開されます。虚偽の情報は禁止されています。',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '店舗選択 *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _isLoadingStores
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : _userStores.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.store, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '作成した店舗がありません',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CreateStoreView(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('店舗を作成'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStoreId,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        hint: const Text('店舗を選択してください'),
                        items: _userStores.map((store) {
                          return DropdownMenuItem<String>(
                            value: store['storeId'],
                            child: Text(store['storeName']),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedStoreId = newValue;
                              _selectedStoreName = _userStores
                                  .firstWhere((store) => store['storeId'] == newValue)['storeName'];
                            });
                          }
                        },
                      ),
                    ),
        ),
        if (_userStores.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '先に店舗を作成してください',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'デバッグ情報: ユーザーID = ${FirebaseAuth.instance.currentUser?.uid ?? '未ログイン'}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '店舗数: ${_userStores.length}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '写真',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                '最大${_maxImages}枚',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              // 選択された画像の表示
              if (_selectedImages.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedImages.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final Uint8List imageBytes = entry.value;
                    
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // 写真追加ボタン
              if (_selectedImages.length < _maxImages)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 32,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '写真を追加',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedImages.length}/${_maxImages}枚選択済み',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '最大枚数の写真が選択されています',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'カテゴリ *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
} 