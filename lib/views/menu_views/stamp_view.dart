import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StampView extends StatefulWidget {
  const StampView({super.key});

  @override
  State<StampView> createState() => _StampViewState();
}

class _StampViewState extends State<StampView> {
  int getAllStamps = 0;
  int totalGoldStamps = 0;  // 全店舗のゴールドスタンプ数の合計
  int totalNormalStamps = 0; // 全店舗の通常スタンプ数の合計
  bool _isLoading = true;
  List<Map<String, dynamic>> _storeStamps = [];

  @override
  void initState() {
    super.initState();
    _loadStampData();
  }

  // スタンプデータを読み込み
  Future<void> _loadStampData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('ユーザーID: ${user.uid}');
        
        // ユーザーコレクションからスタンプデータを取得
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          print('ユーザーデータ: $userData');
          
          // ユーザーの総スタンプ数を取得（もし存在する場合）
          if (userData.containsKey('totalStamps')) {
            getAllStamps = userData['totalStamps'] ?? 0;
            print('ユーザーから取得した総スタンプ数: $getAllStamps');
          }
        }
        
        // 新しいuser_stamps構造からスタンプデータを取得
        final userStampsSnapshot = await FirebaseFirestore.instance
            .collection('user_stamps')
            .doc(user.uid)
            .collection('stores')
            .get();
        
        print('取得した店舗数: ${userStampsSnapshot.docs.length}');
        
        final List<Map<String, dynamic>> storeStamps = [];
        int totalStamps = 0; // 総スタンプ数を計算
        
        for (final storeDoc in userStampsSnapshot.docs) {
          final storeData = storeDoc.data();
          final storeId = storeDoc.id;
          
          print('店舗ID: $storeId, スタンプ数: ${storeData['stamps']}');
          
          // 店舗情報を取得
          final storeInfoDoc = await FirebaseFirestore.instance
              .collection('stores')
              .doc(storeId)
              .get();
          
          if (storeInfoDoc.exists) {
            final storeInfo = storeInfoDoc.data()!;
            final stampCount = (storeData['stamps'] ?? 0) as int;
            final isGoldStamp = stampCount >= 10;
            
            totalStamps += stampCount;
            
            storeStamps.add({
              'storeId': storeId,
              'storeName': storeInfo['name'] ?? '不明な店舗',
              'stamps': stampCount,
              'isGoldStamp': isGoldStamp,
              'lastStampDate': storeData['lastStampDate'],
              'firstStampDate': storeData['firstStampDate'],
            });
          }
        }
        
        // スタンプ数でソート（多い順）
        storeStamps.sort((a, b) => (b['stamps'] as int).compareTo(a['stamps'] as int));
        
        // 各店舗のゴールドスタンプ数と通常スタンプ数を計算
        int totalGoldStampsCount = 0;
        int totalNormalStampsCount = 0;
        
        for (final store in storeStamps) {
          final stampCount = store['stamps'] as int;
          if (stampCount >= 10) {
            totalGoldStampsCount += 1; // 10個以上でゴールドスタンプ
          } else {
            totalNormalStampsCount += stampCount; // 通常スタンプ数
          }
        }
        
        // 総スタンプ数を設定
        getAllStamps = totalStamps;
        totalGoldStamps = totalGoldStampsCount;
        totalNormalStamps = totalNormalStampsCount;
        
        print('総スタンプ数: $totalStamps');
        print('ゴールドスタンプ数: $totalGoldStamps');
        print('通常スタンプ数: $totalNormalStamps');
        
        setState(() {
          _storeStamps = storeStamps;
          _isLoading = false;
        });
        
      } else {
        print('ユーザーが認証されていません');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print('スタンプデータの読み込みエラー: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'スタンプ',
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // スタンプ数カード
                  Container(
                    width: 320,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        // プロフィール画像
                        Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(left: 20, right: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                        // スタンプ数情報
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'スタンプ数',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '$getAllStamps',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  ' 個',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // ゴールドスタンプと通常スタンプの個数表示（store_detail_view.dartのスタイルに統一）
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
                            ClipOval(
                              child: Image.asset(
                                'assets/images/gold_coin_icon.png',
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // 画像が読み込めない場合のフォールバック
                                  return Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'スタンプ統計',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // スタンプ統計情報
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
                                    '$totalNormalStamps',
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
                                    '$totalGoldStamps',
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
                  
                  const SizedBox(height: 30),
                  
                  // スタンプカード一覧タイトル
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'スタンプカード一覧',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // データベースのスタンプカード一覧を表示
                  if (_storeStamps.isNotEmpty)
                    ..._storeStamps.map((store) => _buildStoreStampCard(
                      storeName: store['storeName'],
                      stampCount: store['stamps'],
                      isGold: store['isGoldStamp'],
                      storeId: store['storeId'],
                    )),
                  
                  if (_storeStamps.isEmpty)
                    Container(
                      width: 320,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          'スタンプデータがありません',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // 店舗のスタンプカード（store_detail_view.dartのスタイルに統一）
  Widget _buildStoreStampCard({
    required String storeName,
    required int stampCount,
    required bool isGold,
    required String storeId,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isGold ? Border.all(color: Colors.amber, width: 3) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // ゴールドバッジ
              if (isGold)
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // スタンプグリッド（store_detail_view.dartのスタイルに統一）
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
              bool isCollected = index < stampCount;
              bool isGoldStamp = index == 0 || index == 2 || index == 4 || index == 9; // 1個目、3個目、5個目、10個目
              
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isGoldStamp && !isCollected 
                      ? Border.all(color: Colors.amber, width: 2)
                      : null,
                ),
                child: ClipOval(
                  child: isCollected
                      ? Image.asset(
                          isGoldStamp 
                              ? 'assets/images/gold_coin_icon.png'
                              : 'assets/images/silver_coin_icon.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // 画像が読み込めない場合のフォールバック
                            return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  isGoldStamp ? Icons.star : Icons.check,
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: isGoldStamp
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipOval(
                                        child: Image.asset(
                                          'assets/images/gold_coin_icon.png',
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.star,
                                              color: Colors.amber[700],
                                              size: 20,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ゴールドスタンプ',
                                        style: TextStyle(
                                          color: Colors.amber[700],
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 15),
          
        ],
      ),
    );
  }
} 