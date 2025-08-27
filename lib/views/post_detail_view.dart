import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'menu_views/store_detail_view.dart';

class PostDetailView extends StatefulWidget {
  final String postId;
  
  const PostDetailView({super.key, required this.postId});

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> with TickerProviderStateMixin {
  bool isHeart = false;
  int selectedTab = 0;
  bool isShowCommentView = false;
  bool isShowGoodMessage = false;
  String commentText = "";
  final PageController _pageController = PageController();
  
  // 投稿データ
  Map<String, dynamic>? _postData;
  bool _isLoading = true;
  String? _error;
  
  // 画像リスト
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  // 投稿データを読み込み
  Future<void> _loadPostData() async {
    try {
      print('投稿読み込み開始: ${widget.postId}');
      
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();
      
      if (!postDoc.exists) {
        throw Exception('投稿が見つかりません');
      }
      
      final data = postDoc.data()!;
      print('投稿データ: $data');
      
      // 画像URLを処理
      final imageUrls = data['imageUrls'] as List?;
      final images = data['images'] as List?; // 旧形式との互換性
      
      List<String> processedImageUrls = [];
      
      if (imageUrls != null && imageUrls.isNotEmpty) {
        processedImageUrls = imageUrls.cast<String>();
      } else if (images != null && images.isNotEmpty) {
        // 旧形式の場合、Base64データをData URLに変換
        processedImageUrls = images.map((img) => 'data:image/jpeg;base64,$img').cast<String>().toList();
      }
      
      if (mounted) {
        setState(() {
          _postData = data;
          _imageUrls = processedImageUrls;
          _isLoading = false;
        });
      }
      
      // 店舗アイコン画像URLも取得
      if (data['storeIconImageUrl'] != null) {
        print('店舗アイコン画像URL: ${data['storeIconImageUrl']}');
      }
      
      print('画像URL数: ${_imageUrls.length}');
    } catch (e) {
      print('投稿読み込みエラー: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  // 日付フォーマット
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '日付不明';
    
    try {
      final date = timestamp.toDate();
      return '${date.year}年${date.month}月${date.day}日';
    } catch (e) {
      return '日付不明';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // backWhite
      appBar: AppBar(
        title: const Text(
          '投稿詳細',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'エラーが発生しました',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          // 店舗情報
                          GestureDetector(
                            onTap: () {
                              final storeId = _postData?['storeId'];
                              if (storeId != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => StoreDetailView(storeId: storeId),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                children: [
                                  const SizedBox(width: 20),
                                  // 店舗アイコン
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: _postData?['storeIconImageUrl']?.isNotEmpty == true
                                          ? Image.network(
                                              _postData!['storeIconImageUrl'],
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.store,
                                                  color: Colors.grey,
                                                  size: 20,
                                                );
                                              },
                                            )
                                          : const Icon(
                                              Icons.store,
                                              color: Colors.grey,
                                              size: 20,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // 店舗名
                                  Expanded(
                                    child: Text(
                                      _postData?['storeName'] ?? '店舗名不明',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                ],
                              ),
                            ),
                          ),
                          
                          // 投稿タイトル
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                            child: Text(
                              _postData?['title'] ?? 'タイトルなし',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          // 画像スライダー
                          if (_imageUrls.isNotEmpty) ...[
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.width,
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    selectedTab = index;
                                  });
                                },
                                itemCount: _imageUrls.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _buildImage(_imageUrls[index]),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            // ページインジケーター
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _imageUrls.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selectedTab == index ? const Color(0xFFFF6B35) : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // 画像がない場合のプレースホルダー
                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: 200,
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          
                          // 日付
                          Padding(
                            padding: const EdgeInsets.only(top: 10, right: 20),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _formatDate(_postData?['createdAt']),
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 10),
                          
                          // ボタン類
                          _buildButtonsView(),
                          
                          const SizedBox(height: 10),
                          
                          // 投稿内容
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Text(
                              _postData?['content'] ?? '内容がありません',
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 100), // コメント欄のスペース
                        ],
                      ),
                    ),
                    
                    // いいねメッセージ
                    if (isShowGoodMessage)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'いいねしました',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // コメント欄
          if (isShowCommentView)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCommentView(),
                    ),
                  ],
                ),
    );
  }
  
  // 画像を表示するウィジェット
  Widget _buildImage(String imageUrl) {
    print('詳細画面で画像表示: $imageUrl');
    
    // Base64データかどうかをチェック
    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
        );
      } catch (e) {
        print('Base64デコードエラー: $e');
        return _buildErrorImage();
      }
    } else {
      // Firebase Storage URLの場合
      print('詳細画面でFirebase Storage URL検出: $imageUrl');
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
        cacheWidth: 800,
        cacheHeight: 800,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFFFF6B35),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '画像読み込み中...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('詳細画面で画像読み込みエラー: $imageUrl, エラー: $error');
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '画像の読み込みに失敗しました',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'URL: ${imageUrl.length > 50 ? '${imageUrl.substring(0, 50)}...' : imageUrl}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
  
  Widget _buildErrorImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.broken_image,
        size: 80,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildButtonsView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          // いいねボタン
          GestureDetector(
            onTap: () {
              setState(() {
                isHeart = !isHeart;
                if (isHeart) {
                  isShowGoodMessage = true;
                  // 2秒後にメッセージを非表示
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() {
                        isShowGoodMessage = false;
                      });
                    }
                  });
                }
              });
              // ハプティックフィードバック
              HapticFeedback.lightImpact();
            },
            child: Icon(
              isHeart ? Icons.favorite : Icons.favorite_border,
              color: isHeart ? Colors.pink : Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            '7',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          
          // 閲覧数
          const Icon(
            Icons.visibility,
            color: Colors.black,
            size: 20,
          ),
          const SizedBox(width: 5),
          const Text(
            '20',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          
          // コメント数
          GestureDetector(
            onTap: () {
              setState(() {
                isShowCommentView = !isShowCommentView;
              });
              // ハプティックフィードバック
              HapticFeedback.lightImpact();
            },
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            '1',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentView() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // タイトル
          const Text(
            'コメント',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 10),
          
          // コメント一覧
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 9,
              itemBuilder: (context, index) {
                return _buildCommentBar();
              },
            ),
          ),
          
          // コメント入力欄
          _buildChatButtonBar(),
        ],
      ),
    );
  }

  Widget _buildCommentBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // プロフィール画像
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.grey,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 10),
          
          // コメント内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '金子広樹',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'こんなにまずい料理は初めてです。けど、また行きたい...（情緒不安定）',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButtonBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: Row(
        children: [
          // プロフィール画像
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.grey,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 10),
          
          // テキストフィールド
          Expanded(
            child: TextField(
              controller: TextEditingController(text: commentText),
              onChanged: (value) {
                setState(() {
                  commentText = value;
                });
                // 最大文字数制限（100文字）
                if (value.length > 100) {
                  setState(() {
                    commentText = value.substring(0, 100);
                  });
                }
              },
              decoration: InputDecoration(
                hintText: commentText.isEmpty ? 'コメントを入力' : '最大文字数100文字',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
              maxLines: null,
            ),
          ),
          
          const SizedBox(width: 10),
          
          // 送信ボタン
          GestureDetector(
            onTap: commentText.isNotEmpty ? () {
              // コメント送信処理（後で実装）
              setState(() {
                commentText = "";
              });
            } : null,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: commentText.isNotEmpty ? Colors.blue : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 