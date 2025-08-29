import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'post_detail_view.dart';
import 'coupon_detail_view.dart';

class PostView extends StatefulWidget {
  final bool isShowCouponView;
  final Function(bool) onCouponViewChanged;

  const PostView({
    super.key,
    required this.isShowCouponView,
    required this.onCouponViewChanged,
  });

  @override
  State<PostView> createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
  Tab _selectedTab = Tab.post;
  
  // 投稿データ
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingPosts = true;
  
  // クーポンデータ
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoadingCoupons = true;

  @override
  void initState() {
    super.initState();
    if (widget.isShowCouponView) {
      _selectedTab = Tab.coupon;
    } else {
      _selectedTab = Tab.post;
    }
    _loadPosts();
    _loadCoupons();
  }
  
  @override
  void didUpdateWidget(PostView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // isShowCouponViewの値が変わった場合、タブを更新
    if (widget.isShowCouponView != oldWidget.isShowCouponView) {
      setState(() {
        if (widget.isShowCouponView) {
          _selectedTab = Tab.coupon;
        } else {
          _selectedTab = Tab.post;
        }
      });
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面が表示されるたびに投稿データを再読み込み
    _loadPosts();
  }
  
  // 投稿データを読み込み
  Future<void> _loadPosts() async {
    try {
      print('投稿一覧読み込み開始');
      
      // インデックス問題を回避するため、フィルタを簡素化
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      print('投稿一覧取得数: ${postsSnapshot.docs.length}');

      if (mounted) {
        setState(() {
          _posts = postsSnapshot.docs
              .where((doc) {
                final data = doc.data();
                // アプリ側でフィルタリング
                return (data['isActive'] ?? false) == true && 
                       (data['isPublished'] ?? false) == true;
              })
              .map((doc) {
                final data = doc.data();
                return {
                  'postId': data['postId'] ?? doc.id,
                  'title': data['title'] ?? 'タイトルなし',
                  'content': data['content'] ?? '',
                  'storeName': data['storeName'] ?? '店舗名なし',
                  'category': data['category'] ?? 'お知らせ',
                  'createdAt': data['createdAt'],
                  'imageUrls': data['imageUrls'] ?? [],
                  'images': data['images'] ?? [], // 旧形式との互換性
                  'imageCount': data['imageCount'] ?? 0,
                  'storeIconImageUrl': data['storeIconImageUrl'], // 店舗アイコン画像URLを追加
                };
              })
              .toList();
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('投稿一覧読み込みエラー: $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }
  
  // クーポンデータを読み込み
  Future<void> _loadCoupons() async {
    try {
      print('クーポン一覧読み込み開始');
      
      // インデックス問題を回避するため、シンプルなクエリを使用
      final couponsSnapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .limit(50)
          .get();

      print('クーポン一覧取得数: ${couponsSnapshot.docs.length}');

      if (mounted) {
        setState(() {
          _coupons = couponsSnapshot.docs.map((doc) {
            final data = doc.data();
            final endDate = data['endDate'];
            final now = DateTime.now();
            
            // クライアントサイドで使用可能期間と使用済みをチェック
            bool isAvailable = false;
            DateTime? startDateTime;
            DateTime? endDateTime;
            
            try {
              // 開始日をチェック
              if (data['startDate'] != null) {
                startDateTime = (data['startDate'] as Timestamp).toDate();
              }
              
              // 終了日をチェック
              if (endDate != null) {
                endDateTime = (endDate as Timestamp).toDate();
              }
              
              // 今日の日付（時刻を除く）
              final today = DateTime(now.year, now.month, now.day);
              
              // 開始日以降で終了日未満かチェック
              if (startDateTime != null && endDateTime != null) {
                final startDateOnly = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
                final endDateOnly = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
                isAvailable = today.isAfter(startDateOnly.subtract(const Duration(days: 1))) && 
                             today.isBefore(endDateOnly.add(const Duration(days: 1)));
              } else if (startDateTime != null) {
                // 開始日のみ設定されている場合
                final startDateOnly = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
                isAvailable = today.isAfter(startDateOnly.subtract(const Duration(days: 1)));
              } else if (endDateTime != null) {
                // 終了日のみ設定されている場合
                final endDateOnly = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
                isAvailable = today.isBefore(endDateOnly.add(const Duration(days: 1)));
              } else {
                // 日付が設定されていない場合は使用可能とする
                isAvailable = true;
              }
              
              // 使用済みかチェック（ログインユーザーの場合のみ）
              if (isAvailable) {
                final usedUserIds = List<String>.from(data['usedUserIds'] ?? []);
                // ログインユーザーがいる場合は使用済みをチェック
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null && usedUserIds.contains(currentUser.uid)) {
                  isAvailable = false;
                }
              }
            } catch (e) {
              print('日付変換エラー: $e');
              isAvailable = false;
            }
            
            return {
              'couponId': doc.id,
              'title': data['title'] ?? 'タイトルなし',
              'description': data['description'] ?? '',
              'discountType': data['discountType'] ?? '割引率',
              'discountValue': data['discountValue'] ?? '',
              'startDate': data['startDate'],
              'endDate': data['endDate'],
              'startDateTime': startDateTime, // ソート用のDateTime
              'endDateTime': endDateTime, // ソート用のDateTime
              'imageUrl': data['imageUrl'],
              'storeName': data['storeName'] ?? '店舗名なし',
              'conditions': data['conditions'] ?? '',
              'isAvailable': isAvailable,
            };
          })
          .where((coupon) => coupon['isAvailable'] == true) // 使用可能なクーポンのみ
          .toList()
          ..sort((a, b) {
            // 期限が近い順にソート
            final aEndDate = a['endDateTime'] as DateTime?;
            final bEndDate = b['endDateTime'] as DateTime?;
            
            if (aEndDate == null && bEndDate == null) return 0;
            if (aEndDate == null) return 1;
            if (bEndDate == null) return -1;
            
            return aEndDate.compareTo(bEndDate);
          });
          _isLoadingCoupons = false;
        });
      }
    } catch (e) {
      print('クーポン一覧読み込みエラー: $e');
      if (mounted) {
        setState(() {
          _isLoadingCoupons = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // backWhite
      body: Column(
        children: [
          const SizedBox(height: 20),
          // タイトル
          const Text(
            '投稿・クーポン',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          // カスタムタブバー
          Row(
            children: [
              Expanded(
                child: _buildCustomTabBar(Tab.post, '投稿', Icons.grid_on),
              ),
              Expanded(
                child: _buildCustomTabBar(Tab.coupon, 'クーポン', Icons.qr_code),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // タブコンテンツ
          Expanded(
            child: _selectedTab == Tab.post
                ? _buildPostView()
                : _buildCouponView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(Tab tab, String text, IconData icon) {
    bool isSelected = _selectedTab == tab;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            child: Icon(
              icon,
              color: isSelected 
                  ? const Color(0xFFFF6B35) // GourMap color
                  : Colors.black.withOpacity(0.3),
              size: 30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSelected 
                  ? const Color(0xFFFF6B35) // GourMap color
                  : Colors.black.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            color: isSelected 
                ? const Color(0xFFFF6B35) // GourMap color
                : Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildPostView() {
    if (_isLoadingPosts) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }
    
    if (_posts.isEmpty) {
      return const Center(
        child: Text(
          '投稿がありません',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 170 / 325,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(_posts[index]);
      },
    );
  }

  Widget _buildCouponView() {
    if (_isLoadingCoupons) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }
    
    if (_coupons.isEmpty) {
      return const Center(
        child: Text(
          '利用可能なクーポンがありません',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 170 / 280,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _coupons.length,
      itemBuilder: (context, index) {
        return _buildCouponCard(_coupons[index]);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    // 日付フォーマット
    String formatDate() {
      final createdAt = post['createdAt'];
      if (createdAt == null) return '日付不明';
      
      try {
        final date = (createdAt as Timestamp).toDate();
        return '${date.year}年${date.month}月${date.day}日';
      } catch (e) {
        return '日付不明';
      }
    }

    // 画像を取得
    Widget buildImage() {
      // 新しい形式のimageUrlsをチェック
      final imageUrls = post['imageUrls'] as List?;
      if (imageUrls != null && imageUrls.isNotEmpty) {
        final imageUrl = imageUrls[0] as String;
        
        // Base64データかどうかをチェック
        if (imageUrl.startsWith('data:image/')) {
          try {
            final base64String = imageUrl.split(',')[1];
            final imageBytes = base64Decode(base64String);
            return ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.memory(
                imageBytes,
                width: 150,
                height: 150,
                fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
              ),
            );
          } catch (e) {
            print('Base64デコードエラー: $e');
          }
        } else {
          // Firebase Storage URLの場合
          print('投稿一覧でFirebase Storage URL検出: $imageUrl');
          
          // Webプラットフォームでの画像読み込みを改善
          try {
            // 画像URLの検証
            if (imageUrl.isEmpty || !Uri.tryParse(imageUrl)!.isAbsolute) {
              print('無効な画像URL: $imageUrl');
              return _buildDefaultImage();
            }
            
            // Web用の画像読み込み処理 - CORS問題を回避するため、より堅牢な処理
            return ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: FutureBuilder<Widget>(
                future: _loadImageWithFallback(imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFFFF6B35),
                        ),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData) {
                    print('画像読み込みエラー: $imageUrl, エラー: ${snapshot.error}');
                    return _buildDefaultImage();
                  }
                  
                  return snapshot.data!;
                },
              ),
            );
          } catch (e) {
            print('画像読み込みで例外が発生: $e');
            // エラーが発生した場合はデフォルト画像を表示
            return _buildDefaultImage();
          }
        }
      }
      
      // 旧形式のimagesフィールドもチェック（後方互換性）
      final images = post['images'] as List?;
      if (images != null && images.isNotEmpty) {
        try {
          final base64String = images[0] as String;
          final imageBytes = base64Decode(base64String);
          return ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.memory(
              imageBytes,
              width: 150,
              height: 150,
              fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
            ),
          );
        } catch (e) {
          print('旧形式画像デコードエラー: $e');
        }
      }
      
      // デフォルト画像
      return _buildDefaultImage();
    }
    
    return GestureDetector(
      onTap: () {
        final postId = post['postId'];
        if (postId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailView(postId: postId),
            ),
          );
        }
      },
      child: Container(
        width: 170,
        height: 325,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // 画像
            Container(
              margin: const EdgeInsets.only(top: 7, bottom: 7),
              child: buildImage(),
            ),
            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                post['title'] ?? 'タイトルなし',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 5),
            // 内容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                post['content'] ?? '',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 5),
            // 区切り線
            Container(
              height: 0.5,
              color: Colors.grey,
              margin: const EdgeInsets.symmetric(horizontal: 10),
            ),
            const SizedBox(height: 5),
            // 店舗アイコンと店舗名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 店舗アイコン
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: post['storeIconImageUrl'] != null
                          ? Image.network(
                              post['storeIconImageUrl'],
                              width: 16,
                              height: 16,
                              fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.store,
                                  color: Colors.grey,
                                  size: 10,
                                );
                              },
                            )
                          : const Icon(
                              Icons.store,
                              color: Colors.grey,
                              size: 10,
                            ),
                    ),
                  ),
                  // 店舗名
                  Expanded(
                    child: Text(
                      post['storeName'] ?? '店舗名なし',
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            // 日付
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  formatDate(),
                  style: const TextStyle(
                    fontSize: 7,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    // 終了日の表示用フォーマット
    String formatEndDate() {
      final endDate = coupon['endDate'];
      if (endDate == null) return '期限不明';
      
      try {
        final date = (endDate as Timestamp).toDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final couponDate = DateTime(date.year, date.month, date.day);
        
        String dateText;
        if (couponDate.isAtSameMomentAs(today)) {
          dateText = '今日';
        } else if (couponDate.isAtSameMomentAs(tomorrow)) {
          dateText = '明日';
        } else {
          dateText = '${date.month}月${date.day}日';
        }
        
        return '$dateText ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}まで';
      } catch (e) {
        return '期限不明';
      }
    }

    // 割引表示用テキスト
    String getDiscountText() {
      final discountType = coupon['discountType'] ?? '割引率';
      final discountValue = coupon['discountValue'] ?? '';
      
      if (discountType == '割引率') {
        return '$discountValue%OFF';
      } else if (discountType == '割引額') {
        return '${discountValue}円OFF';
      } else if (discountType == '固定価格') {
        return '${discountValue}円';
      }
      return '特典あり';
    }

    return GestureDetector(
      onTap: () {
        final couponId = coupon['couponId'];
        if (couponId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CouponDetailView(couponId: couponId),
            ),
          );
        }
      },
      child: Container(
        width: 170,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // 画像
            Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.only(top: 7, bottom: 7),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
              child: coupon['imageUrl'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        coupon['imageUrl'],
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
            ),
            // 期限
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                formatEndDate(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                coupon['title'] ?? 'タイトルなし',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // 割引情報
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                getDiscountText(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            // 店舗名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                coupon['storeName'] ?? '店舗名なし',
                style: const TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // デフォルト画像を表示するヘルパーメソッド
  Widget _buildDefaultImage() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Icon(
        Icons.image,
        size: 50,
        color: Colors.grey,
      ),
    );
  }
  
  // CORS問題を回避するための画像読み込み処理
  Future<Widget> _loadImageWithFallback(String imageUrl) async {
    try {
      // Web用の画像URL最適化
      String optimizedUrl = _optimizeImageUrlForWeb(imageUrl);
      
      // 複数の画像読み込み方法を試行
      return FutureBuilder<Widget>(
        future: _tryMultipleImageLoadingMethods(optimizedUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFFFF6B35),
                ),
              ),
            );
          }
          
          if (snapshot.hasError || !snapshot.hasData) {
            print('画像読み込みでエラー: ${snapshot.error}');
            return _buildDefaultImage();
          }
          
          return snapshot.data!;
        },
      );
    } catch (e) {
      print('画像読み込みで例外が発生: $e');
      return _buildDefaultImage();
    }
  }
  
  // 複数の画像読み込み方法を試行
  Future<Widget> _tryMultipleImageLoadingMethods(String imageUrl) async {
    // 方法1: 通常のImage.network（ルール修正後）
    try {
      return Image.network(
        imageUrl,
        width: 150,
        height: 150,
        fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
        cacheWidth: 300,
        cacheHeight: 300,
        // CORSヘッダーを削除（Firebase Storageの設定に依存）
        errorBuilder: (context, error, stackTrace) {
          print('方法1でエラー: $error');
          return _buildDefaultImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xFFFF6B35),
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('方法1で例外: $e');
    }
    
    // 方法2: 画像URLを直接ブラウザで開く（CORS回避）
    try {
      return GestureDetector(
        onTap: () {
          // 画像を新しいタブで開く
          _openImageInNewTab(imageUrl);
        },
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image,
                size: 40,
                color: Colors.grey,
              ),
              const SizedBox(height: 4),
              const Text(
                '画像をタップして表示',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('方法2で例外: $e');
    }
    
    // 方法3: デフォルト画像
    return _buildDefaultImage();
  }
  
  // 画像を新しいタブで開く
  void _openImageInNewTab(String imageUrl) {
    try {
      // Web用の画像表示
      if (kIsWeb) {
        // 新しいウィンドウで画像を開く
        // html.window.open(imageUrl, '_blank');
        print('Web用画像表示: $imageUrl');
      }
    } catch (e) {
      print('画像表示でエラー: $e');
    }
  }
  
  // プロキシURLを作成（CORS回避のため）
  String _createProxyUrl(String originalUrl) {
    // より実用的なCORS回避方法
    // 1. 画像URLを直接使用（Firebase Storageの設定に依存）
    // 2. 必要に応じて、独自のプロキシサーバーを構築
    return originalUrl;
  }
  
  // Web用の画像URL最適化
  String _optimizeImageUrlForWeb(String originalUrl) {
    try {
      // Firebase Storage URLの場合、Web用のパラメータを追加
      if (originalUrl.contains('firebasestorage.googleapis.com')) {
        // 既存のクエリパラメータがあるかチェック
        if (originalUrl.contains('?')) {
          return '$originalUrl&alt=media&token=${_extractToken(originalUrl)}';
        } else {
          return '$originalUrl?alt=media&token=${_extractToken(originalUrl)}';
        }
      }
      return originalUrl;
    } catch (e) {
      print('URL最適化でエラー: $e');
      return originalUrl;
    }
  }
  
  // URLからトークンを抽出
  String _extractToken(String url) {
    try {
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];
      return token ?? '';
    } catch (e) {
      print('トークン抽出でエラー: $e');
      return '';
    }
  }
}

enum Tab {
  post,
  coupon,
} 