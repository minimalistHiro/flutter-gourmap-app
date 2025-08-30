import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PointHistoryView extends StatefulWidget {
  const PointHistoryView({super.key});

  @override
  State<PointHistoryView> createState() => _PointHistoryViewState();
}

class _PointHistoryViewState extends State<PointHistoryView> {
  // Firebase関連
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ユーザーデータ
  int _totalPoints = 0;
  List<Map<String, dynamic>> _pointHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ユーザーデータを読み込む
  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // ユーザーのポイント情報を取得
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _totalPoints = userData['points'] ?? 0;
        });
      }

      // ポイント履歴を取得
      await _loadPointHistory(user.uid);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('ユーザーデータの読み込みに失敗しました: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ポイント履歴を読み込む
  Future<void> _loadPointHistory(String userId) async {
    try {
      final List<Map<String, dynamic>> history = [];
      
      // point_history コレクションからポイント履歴を取得（獲得・使用両方）
      QuerySnapshot pointHistorySnapshot;
      try {
        // まず複合インデックスを使用したクエリを試す
        pointHistorySnapshot = await _firestore
            .collection('point_history')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();
      } catch (indexError) {
        print('複合インデックスクエリでエラー、単純クエリにフォールバック: $indexError');
        // インデックスエラーの場合、orderByなしでフォールバック
        pointHistorySnapshot = await _firestore
            .collection('point_history')
            .where('userId', isEqualTo: userId)
            .get();
      }
      
      for (final doc in pointHistorySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        final storeId = data['storeId'];
        final type = data['type'] ?? '支払い';
        final source = data['source'] ?? 'unknown';
        
        final transactionType = data['transactionType'] ?? 'earn';
        final points = data['points'] ?? 0;
        
        // スロットやルーレットなど、店舗IDがない場合
        if (storeId == null || source == 'slot_machine' || source == 'roulette') {
          history.add({
            'id': doc.id,
            'storeName': data['storeName'] ?? _getSourceDisplayName(source),
            'storeId': null,
            'points': points,
            'timestamp': data['timestamp'] ?? data['createdAt'] ?? Timestamp.now(),
            'type': type,
            'description': data['description'] ?? '',
            'source': source,
            'transactionType': transactionType,
          });
        } else {
          // 一般的な店舗の場合は店舗情報を取得
          try {
            final storeDoc = await _firestore.collection('stores').doc(storeId).get();
            if (storeDoc.exists) {
              final storeData = storeDoc.data()!;
              history.add({
                'id': doc.id,
                'storeName': storeData['name'] ?? '店舗名なし',
                'storeId': storeId,
                'points': points,
                'timestamp': data['timestamp'] ?? data['createdAt'] ?? Timestamp.now(),
                'type': type,
                'description': data['description'] ?? '',
                'source': source,
                'transactionType': transactionType,
              });
            }
          } catch (e) {
            print('店舗情報の取得に失敗: $e');
            // 店舗情報の取得に失敗した場合もエントリを追加
            history.add({
              'id': doc.id,
              'storeName': data['storeName'] ?? '店舗名なし',
              'storeId': storeId,
              'points': points,
              'timestamp': data['timestamp'] ?? data['createdAt'] ?? Timestamp.now(),
              'type': type,
              'description': data['description'] ?? '',
              'source': source,
              'transactionType': transactionType,
            });
          }
        }
      }

      // タイムスタンプで降順ソート（最新順）
      history.sort((a, b) {
        final aTimestamp = a['timestamp'] as Timestamp;
        final bTimestamp = b['timestamp'] as Timestamp;
        return bTimestamp.compareTo(aTimestamp);
      });

      setState(() {
        _pointHistory = history;
      });
    } catch (e) {
      print('ポイント履歴の読み込みに失敗しました: $e');
    }
  }
  
  // ソース表示名を取得
  String _getSourceDisplayName(String source) {
    switch (source) {
      case 'slot_machine':
        return 'スロット';
      case 'roulette':
        return 'ルーレット';
      case 'store_payment':
        return '店舗決済';
      case 'bonus':
        return 'ボーナス';
      case 'campaign':
        return 'キャンペーン';
      case 'purchase':
        return '商品購入';
      case 'exchange':
        return 'ポイント交換';
      case 'admin':
        return '管理者調整';
      case 'refund':
        return '返金';
      default:
        return 'その他';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // backWhite
      appBar: AppBar(
        title: const Text(
          'ポイント',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadUserData,
            tooltip: '更新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      // 総ポイント数カード
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 350),
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '総ポイント数',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$_totalPoints',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'pt',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // ポイント獲得履歴
                      _buildHistoryView(),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }





  Widget _buildHistoryView() {
    if (_pointHistory.isEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 350),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'ポイント履歴がありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '店舗でポイントを獲得すると、ここに履歴が表示されます',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 350),
      child: Column(
        children: _pointHistory.map((history) => _buildHistoryCard(
          storeName: history['storeName'],
          timestamp: _formatTimestamp(history['timestamp']),
          points: history['points'],
          type: history['type'],
          transactionType: history['transactionType'],
        )).toList(),
      ),
    );
  }



  // タイムスタンプをフォーマットする
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今日';
    } else if (difference.inDays == 1) {
      return '昨日';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${date.year}年${date.month}月${date.day}日';
    }
  }

  // ポイントタイプに応じた色を取得
  Color _getTypeColor(String type) {
    switch (type) {
      case '支払い':
        return Colors.red;
      case 'ボーナス':
        return Colors.blue;
      case '特典':
        return Colors.green;
      case 'キャンペーン':
        return Colors.orange;
      case 'ルーレット':
        return Colors.purple;
      case 'スロット':
        return Colors.deepPurple;
      default:
        return Colors.red;
    }
  }

  Widget _buildHistoryCard({
    required String storeName,
    required String timestamp,
    required int points,
    String? type,
    String? transactionType,
  }) {
    final isEarn = transactionType == 'earn';
    final pointText = '${isEarn ? '+' : '-'}${points.abs()}P';
    final pointColor = isEarn ? const Color(0xFFFF6B35) : Colors.red;
    return Container(
      width: double.infinity,
      height: 90,
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // 店舗画像
          Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.only(left: 20, right: 5),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              (storeName == 'ルーレット' || storeName == 'スロット') ? Icons.casino : Icons.store,
              color: (storeName == 'ルーレット' || storeName == 'スロット') ? Colors.purple : Colors.grey,
              size: 24,
            ),
          ),
          // 店舗情報
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        timestamp,
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: type == 'スロット' ? 50 : 40, // スロットの場合は幅を広げる
                      height: 20,
                      decoration: BoxDecoration(
                        color: _getTypeColor(type ?? '支払い'),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          type ?? '支払い',
                          style: TextStyle(
                            fontSize: type == 'スロット' ? 8 : 10, // スロットの場合は文字を小さく
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      pointText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: pointColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 