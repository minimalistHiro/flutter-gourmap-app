import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../post_detail_view.dart';
import '../map_view.dart'; // MapViewをインポート
import 'dart:convert'; // base64Decodeを追加

class StoreDetailView extends StatefulWidget {
  final String storeId;
  
  const StoreDetailView({
    super.key,
    required this.storeId,
  });

  @override
  State<StoreDetailView> createState() => _StoreDetailViewState();
}

class _StoreDetailViewState extends State<StoreDetailView> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  
  // Firebase関連
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 店舗データ
  Map<String, dynamic>? _storeData;
  bool _isLoading = true;
  
  // ユーザーのスタンプデータ
  int _userGoldStamps = 0;
  int _userRegularStamps = 0;
  
  // 店舗の投稿データ
  List<Map<String, dynamic>> _storePosts = [];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStoreData();
    _loadUserStampData();
  }

  // 店舗データを読み込む
  Future<void> _loadStoreData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final doc = await _firestore.collection('stores').doc(widget.storeId).get();
      if (doc.exists) {
        setState(() {
          _storeData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
        
        // 店舗データ読み込み完了後、投稿データも読み込む
        _loadStorePosts();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('店舗データの読み込みに失敗しました: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ユーザーのスタンプデータを読み込む
  Future<void> _loadUserStampData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 新しいuser_stamps構造からこの店舗のスタンプデータを取得
      final userStampDoc = await _firestore
          .collection('user_stamps')
          .doc(user.uid)
          .collection('stores')
          .doc(widget.storeId)
          .get();

      if (userStampDoc.exists) {
        final data = userStampDoc.data()!;
        setState(() {
          _userGoldStamps = data['goldStamps'] ?? 0;
          _userRegularStamps = data['regularStamps'] ?? 0;
        });
      } else {
        setState(() {
          _userGoldStamps = 0;
          _userRegularStamps = 0;
        });
      }
    } catch (e) {
      print('ユーザースタンプデータの読み込みに失敗しました: $e');
    }
  }

  // スタンプを追加する
  Future<void> _addStamp() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final newRegularStamps = _userRegularStamps + 1;
      int newGoldStamps = _userGoldStamps;
      
      // 1、3、5、10個目のスタンプでゴールドスタンプを増やす
      if (newRegularStamps == 1 || newRegularStamps == 3 || 
          newRegularStamps == 5 || newRegularStamps == 10) {
        newGoldStamps += 1;
      }

      // user_stampsコレクションを更新
      await _firestore
          .collection('user_stamps')
          .doc(user.uid)
          .collection('stores')
          .doc(widget.storeId)
          .set({
        'userId': user.uid,
        'storeId': widget.storeId,
        'regularStamps': newRegularStamps,
        'goldStamps': newGoldStamps,
        'lastStampDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // usersコレクションのgoldStampsとstampsも更新
      await _firestore.collection('users').doc(user.uid).update({
        'goldStamps': FieldValue.increment(1), // ゴールドスタンプが増えた場合のみ
        'stamps': FieldValue.increment(1),     // 通常スタンプを1増やす
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _userRegularStamps = newRegularStamps;
        _userGoldStamps = newGoldStamps;
      });
    } catch (e) {
      print('スタンプ追加に失敗しました: $e');
    }
  }

  // スタンプを削除する
  Future<void> _removeStamp() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (_userRegularStamps <= 0) return;

      final newRegularStamps = _userRegularStamps - 1;
      int adjustedGoldStamps = _userGoldStamps;
      
      // ゴールドスタンプの調整（1、3、5、10個目のスタンプが削除された場合）
      if (_userRegularStamps == 1 || _userRegularStamps == 3 || 
          _userRegularStamps == 5 || _userRegularStamps == 10) {
        adjustedGoldStamps = _userGoldStamps - 1;
      }

      await _firestore
          .collection('user_stamps')
          .doc(user.uid)
          .collection('stores')
          .doc(widget.storeId)
          .set({
        'userId': user.uid,
        'storeId': widget.storeId,
        'regularStamps': newRegularStamps,
        'goldStamps': adjustedGoldStamps,
        'lastStampDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // usersコレクションのgoldStampsとstampsも更新
      final goldStampsDiff = adjustedGoldStamps - _userGoldStamps;
      await _firestore.collection('users').doc(user.uid).update({
        'goldStamps': FieldValue.increment(goldStampsDiff),
        'stamps': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _userRegularStamps = newRegularStamps;
        _userGoldStamps = adjustedGoldStamps;
      });
    } catch (e) {
      print('スタンプ削除に失敗しました: $e');
    }
  }

  // スタンプをリセット
  Future<void> _resetStamps() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 現在のスタンプ数を取得して差分を計算
      final currentRegularStamps = _userRegularStamps;
      final currentGoldStamps = _userGoldStamps;

      await _firestore
          .collection('user_stamps')
          .doc(user.uid)
          .collection('stores')
          .doc(widget.storeId)
          .set({
        'userId': user.uid,
        'storeId': widget.storeId,
        'regularStamps': 0,
        'goldStamps': 0,
        'lastStampDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // usersコレクションのgoldStampsとstampsも更新
      await _firestore.collection('users').doc(user.uid).update({
        'goldStamps': FieldValue.increment(-currentGoldStamps),
        'stamps': FieldValue.increment(-currentRegularStamps),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _userRegularStamps = 0;
        _userGoldStamps = 0;
      });
    } catch (e) {
      print('スタンプリセットに失敗しました: $e');
    }
  }

  // 店舗の投稿データを読み込む
  Future<void> _loadStorePosts() async {
    try {
      setState(() {
        _isLoadingPosts = true;
      });

      print('店舗投稿データ読み込み開始: 店舗ID = ${widget.storeId}');

      // インデックスエラーを回避するため、まず全ての投稿を取得してからフィルタリング
      final postsSnapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      print('取得した投稿数: ${postsSnapshot.docs.length}');
      
      // 店舗IDでフィルタリング
      final filteredPosts = postsSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['storeId'] == widget.storeId && 
               (data['isActive'] ?? false) == true && 
               (data['isPublished'] ?? false) == true;
      }).toList();
      
      print('フィルタリング後の投稿数: ${filteredPosts.length}');
      
      // 各投稿のデータを確認
      for (final doc in filteredPosts) {
        final data = doc.data();
        print('投稿ID: ${doc.id}, データ: $data');
      }

      if (mounted) {
        setState(() {
          _storePosts = filteredPosts.map((doc) {
            final data = doc.data();
            return {
              'postId': data['postId'] ?? doc.id,
              'title': data['title'] ?? 'タイトルなし',
              'content': data['content'] ?? '',
              'category': data['category'] ?? 'お知らせ',
              'createdAt': data['createdAt'],
              'imageUrls': data['imageUrls'] ?? [],
              'images': data['images'] ?? [],
              'imageCount': data['imageCount'] ?? 0,
            };
          }).toList();
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('店舗投稿データの読み込みに失敗しました: $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  // 地図ポップアップを表示
  void _showMapPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 地図コンテンツ
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: MapView(selectedStoreId: widget.storeId),
                ),
                
                // 左上の×ボタン
                Positioned(
                  top: 15,
                  left: 15,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                
                // 右上のタイトル
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '店舗位置',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            '店舗詳細',
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
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
          ),
        ),
      );
    }

    if (_storeData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            '店舗詳細',
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
        body: const Center(
          child: Text(
            '店舗が見つかりません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '店舗詳細',
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
        child: Column(
          children: [
            // 店舗画像
            Container(
              width: double.infinity,
              height: 200, // 2:1比率に調整（画面幅の半分の高さ）
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: _storeData!['storeImageUrl']?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: Image.network(
                        _storeData!['storeImageUrl'],
                        fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.store,
                            size: 80,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.store,
                      size: 80,
                      color: Colors.grey,
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // 店舗名とアイコン
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 店舗アイコン
                  if (_storeData!['iconImageUrl']?.isNotEmpty == true)
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          _storeData!['iconImageUrl'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.store,
                              color: Colors.grey,
                              size: 20,
                            );
                          },
                        ),
                      ),
                    ),
                  // 店舗名
                  Expanded(
                    child: Text(
                      _storeData!['name'] ?? '店舗名なし',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            
            // 店舗説明
            if (_storeData!['description']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _storeData!['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 20),
            
            // スタンプカード
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'スタンプカード',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_userRegularStamps}/10個 - 特定の位置でゴールドスタンプがもらえます',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  
                  // スタンプテストコントロール
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.science,
                              color: Colors.blue[700],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'スタンプテスト',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _addStamp,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('追加', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _removeStamp,
                                icon: const Icon(Icons.remove, size: 16),
                                label: const Text('削除', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _resetStamps,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('リセット', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  // ゴールドスタンプ位置の説明
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '1個目、3個目、5個目、10個目でゴールドスタンプがもらえます！',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      bool isCollected = index < _userRegularStamps;
                      bool isGoldStamp = index == 0 || index == 2 || index == 4 || index == 9; // 1個目、3個目、5個目、10個目
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: isCollected 
                              ? (isGoldStamp ? Colors.amber : Colors.blue)
                              : (isGoldStamp ? Colors.amber.withOpacity(0.3) : Colors.grey[300]),
                          shape: BoxShape.circle,
                          border: isGoldStamp && !isCollected 
                              ? Border.all(color: Colors.amber, width: 2)
                              : null,
                          boxShadow: isCollected && isGoldStamp ? [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ] : null,
                        ),
                        child: Stack(
                          children: [
                            if (isCollected)
                              Icon(
                                isGoldStamp ? Icons.star : Icons.check,
                                color: Colors.white,
                                size: isGoldStamp ? 24 : 20,
                              ),
                            // 未収集のゴールドスタンプ位置に説明文を表示
                            if (isGoldStamp && !isCollected)
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber[600],
                                      size: 16,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ゴールド',
                                      style: TextStyle(
                                        color: Colors.amber[700],
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // スタンプ統計情報
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '$_userRegularStamps',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              '全スタンプ',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        Column(
                          children: [
                            Text(
                              '$_userGoldStamps',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                            const Text(
                              'ゴールドスタンプ',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // クーポン一覧
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'クーポン',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              '25%OFF\nクーポン',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // タブバー
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton('投稿', 0),
                  ),
                  Expanded(
                    child: _buildTabButton('メニュー', 1),
                  ),
                  Expanded(
                    child: _buildTabButton('情報', 2),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // タブコンテンツ
            _buildTabContent(),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildPostView();
      case 1:
        return _buildMenuView();
      case 2:
        return _buildInfoView();
      default:
        return _buildPostView();
    }
  }

  Widget _buildPostView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '投稿',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          
          if (_isLoadingPosts)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            )
          else if (_storePosts.isEmpty)
            Column(
              children: [
                const Center(
                  child: Text(
                    'この店舗からの投稿はありません',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // デバッグ情報
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'デバッグ情報:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '店舗ID: ${widget.storeId}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        '投稿数: ${_storePosts.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _storePosts.length,
              itemBuilder: (context, index) {
                final post = _storePosts[index];
                return _buildPostCard(post);
              },
            ),
        ],
      ),
    );
  }

  // 投稿カードを作成
  Widget _buildPostCard(Map<String, dynamic> post) {
    // 作成日の表示用フォーマット
    String formatDate() {
      final createdAt = post['createdAt'];
      if (createdAt == null) return '日付不明';
      
      try {
        final date = (createdAt as Timestamp).toDate();
        final now = DateTime.now();
        final difference = now.difference(date).inDays;
        
        if (difference == 0) return '今日';
        if (difference == 1) return '昨日';
        if (difference < 7) return '${difference}日前';
        
        return '${date.month}月${date.day}日';
      } catch (e) {
        return '日付不明';
      }
    }

    // 画像を取得
    Widget buildImage() {
      Widget buildErrorImage() {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.image,
            color: Colors.grey,
            size: 30,
          ),
        );
      }
      
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
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                imageBytes,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            );
          } catch (e) {
            print('Base64デコードエラー: $e');
            return buildErrorImage();
          }
        } else {
          // Firebase Storage URLの場合
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return buildErrorImage();
              },
            ),
          );
        }
      }
      
      // 旧形式のimagesフィールドもチェック（後方互換性）
      final images = post['images'] as List?;
      if (images != null && images.isNotEmpty) {
        try {
          final base64String = images[0] as String;
          final imageBytes = base64Decode(base64String);
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              imageBytes,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          );
        } catch (e) {
          print('旧形式画像デコードエラー: $e');
          return buildErrorImage();
        }
      }
      
      return buildErrorImage();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像
            Expanded(
              child: buildImage(),
            ),
            
            // 投稿情報
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カテゴリバッジ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF6B35).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      post['category'] ?? 'お知らせ',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // タイトル
                  Text(
                    post['title'] ?? 'タイトルなし',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // 投稿日
                  Text(
                    formatDate(),
                    style: const TextStyle(
                      fontSize: 8,
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

  Widget _buildMenuView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'メニュー',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildCustomMenu('カフェラテ', '¥450'),
          _buildCustomMenu('カプチーノ', '¥450'),
          _buildCustomMenu('エスプレッソ', '¥350'),
          _buildCustomMenu('カレーケサディーヤ', '¥800'),
        ],
      ),
    );
  }

  Widget _buildCustomMenu(String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '店舗情報',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          
          // 基本情報
          if (_storeData!['address']?.isNotEmpty == true) ...[
            _buildInfoRow(
              icon: Icons.location_on,
              title: '住所',
              content: _storeData!['address'],
            ),
            const SizedBox(height: 12),
          ],
          
          if (_storeData!['phone']?.isNotEmpty == true) ...[
            _buildPhoneRow(_storeData!['phone']),
            const SizedBox(height: 12),
          ],
          
          if (_storeData!['socialMedia']?['website']?.isNotEmpty == true) ...[
            _buildInfoItem(
              icon: Icons.language,
              title: 'WEBサイト',
              onTap: () async {
                final url = Uri.parse(_storeData!['socialMedia']['website']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          
          // カテゴリ
          if (_storeData!['category']?.isNotEmpty == true) ...[
            _buildInfoRow(
              icon: Icons.category,
              title: 'カテゴリ',
              content: _storeData!['category'],
            ),
            const SizedBox(height: 12),
          ],
          
          // 営業時間
          if (_storeData!['businessHours'] != null) ...[
            const Text(
              '営業時間',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 8),
            _buildBusinessHours(),
            const SizedBox(height: 16),
          ],
          
          // タグ
          if (_storeData!['tags']?.isNotEmpty == true) ...[
            const Text(
              'タグ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_storeData!['tags'] as List).map<Widget>((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
                  ),
                  child: Text(
                    tag.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF6B35),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // SNS
          if (_hasSocialMedia()) ...[
            const Text(
              'SNS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 15,
              runSpacing: 10,
              children: [
                if (_storeData!['socialMedia']?['facebook']?.isNotEmpty == true)
                  _buildSnsIcon(Icons.facebook, Colors.blue, _storeData!['socialMedia']['facebook']),
                if (_storeData!['socialMedia']?['instagram']?.isNotEmpty == true)
                  _buildSnsIcon(Icons.photo_camera, Colors.purple, _storeData!['socialMedia']['instagram']),
                if (_storeData!['socialMedia']?['x']?.isNotEmpty == true)
                  _buildSnsIcon(Icons.chat_bubble, Colors.black, _storeData!['socialMedia']['x']),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // 住所の場合のみ地図ボタンを表示
        if (title == '住所')
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                _showMapPopup();
              },
              icon: const Icon(Icons.map, size: 16),
              label: const Text(
                '地図',
                style: TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35), // オレンジ色
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhoneRow(String phoneNumber) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.phone,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '電話番号',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                phoneNumber,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final phone = phoneNumber.replaceAll(RegExp(r'[^\d-]'), '');
            final url = Uri.parse('tel:$phone');
            try {
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('電話アプリを開けませんでした')),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('エラー: $e')),
                );
              }
            }
          },
          icon: const Icon(Icons.phone, size: 16),
          label: const Text(
            '電話する',
            style: TextStyle(fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBusinessHours() {
    final businessHours = _storeData!['businessHours'] as Map<String, dynamic>;
    final dayNames = {
      'monday': '月曜日',
      'tuesday': '火曜日',
      'wednesday': '水曜日',
      'thursday': '木曜日',
      'friday': '金曜日',
      'saturday': '土曜日',
      'sunday': '日曜日',
    };
    
    return Column(
      children: dayNames.entries.map((entry) {
        final dayKey = entry.key;
        final dayName = entry.value;
        final dayData = businessHours[dayKey];
        
        if (dayData == null) return const SizedBox.shrink();
        
        final isOpen = dayData['isOpen'] ?? false;
        final openTime = dayData['open'] ?? '';
        final closeTime = dayData['close'] ?? '';
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOpen ? '$openTime - $closeTime' : '定休日',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOpen ? Colors.black87 : Colors.red[600],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  bool _hasSocialMedia() {
    final socialMedia = _storeData!['socialMedia'];
    if (socialMedia == null) return false;
    
    return (socialMedia['facebook']?.isNotEmpty == true) ||
           (socialMedia['instagram']?.isNotEmpty == true) ||
           (socialMedia['x']?.isNotEmpty == true);
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnsIcon(IconData icon, Color color, [String? url]) {
    return GestureDetector(
      onTap: () async {
        if (url != null && url.isNotEmpty) {
          try {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('リンクを開けませんでした')),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('エラー: $e')),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('リンクが設定されていません')),
          );
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
} 