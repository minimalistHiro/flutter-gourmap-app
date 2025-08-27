import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'store_detail_view.dart';

class StoreListView extends StatefulWidget {
  const StoreListView({super.key});

  @override
  State<StoreListView> createState() => _StoreListViewState();
}

class _StoreListViewState extends State<StoreListView> {
  // Firebase関連
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 店舗データ
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;
  
  // 県ごとの店舗グループ
  Map<String, List<Map<String, dynamic>>> _storesByPrefecture = {};

  @override
  void initState() {
    super.initState();
    _loadStoresFromDatabase();
  }

  // データベースから店舗を読み込む
  Future<void> _loadStoresFromDatabase() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final QuerySnapshot snapshot = await _firestore.collection('stores').get();
      final List<Map<String, dynamic>> stores = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isActive'] == true && data['isApproved'] == true) {
          stores.add({
            'id': doc.id,
            'name': data['name'] ?? '店舗名なし',
            'category': data['category'] ?? 'その他',
            'description': data['description'] ?? '',
            'address': data['address'] ?? '',
            'prefecture': _extractPrefecture(data['address'] ?? ''),
            'image': data['storeImageUrl']?.isNotEmpty == true ? data['storeImageUrl'] : null,
          });
        }
      }
      
      // 県ごとに店舗をグループ化
      _groupStoresByPrefecture(stores);
      
      setState(() {
        _stores = stores;
        _isLoading = false;
      });
    } catch (e) {
      print('店舗データの読み込みに失敗しました: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 住所から県名を抽出
  String _extractPrefecture(String address) {
    if (address.isEmpty) return 'その他';
    
    // 日本の都道府県リスト
    final prefectures = [
      '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
      '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
      '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
      '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
      '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
      '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
      '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
    ];
    
    for (final prefecture in prefectures) {
      if (address.contains(prefecture)) {
        return prefecture;
      }
    }
    
    return 'その他';
  }

  // 県ごとに店舗をグループ化
  void _groupStoresByPrefecture(List<Map<String, dynamic>> stores) {
    _storesByPrefecture.clear();
    
    for (final store in stores) {
      final prefecture = store['prefecture'];
      if (!_storesByPrefecture.containsKey(prefecture)) {
        _storesByPrefecture[prefecture] = [];
      }
      _storesByPrefecture[prefecture]!.add(store);
    }
    
    // 県名でソート
    final sortedKeys = _storesByPrefecture.keys.toList()
      ..sort((a, b) {
        if (a == 'その他') return 1;
        if (b == 'その他') return -1;
        return a.compareTo(b);
      });
    
    final sortedMap = <String, List<Map<String, dynamic>>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = _storesByPrefecture[key]!;
    }
    _storesByPrefecture = sortedMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '店舗一覧',
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
            onPressed: _loadStoresFromDatabase,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            )
          : _stores.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Column(
                    children: _storesByPrefecture.entries
                        .map((entry) => _buildPrefectureStoresView(entry.key, entry.value))
                        .toList(),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '店舗が見つかりません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '承認済みの店舗が登録されていないか、\nデータの読み込みに失敗しました',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStoresFromDatabase,
            icon: const Icon(Icons.refresh),
            label: const Text('再読み込み'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrefectureStoresView(String prefecture, List<Map<String, dynamic>> stores) {
    return Column(
      children: [
        // 県名ヘッダー
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: const Color(0xFFFF6B35),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                prefecture,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${stores.length}店舗',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFFF6B35),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 店舗グリッド
        Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              return _buildStoreItem(stores[index]);
            },
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStoreItem(Map<String, dynamic> store) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoreDetailView(storeId: store['id']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 店舗画像
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: store['image'] != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          store['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.store,
                                color: Colors.grey,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.store,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),
            
            // 店舗情報
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 店舗名
                  Text(
                    store['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // カテゴリ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      store['category'],
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFFFF6B35),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  if (store['description']?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      store['description'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 