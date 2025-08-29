import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CouponDetailView extends StatefulWidget {
  final String? couponId;
  
  const CouponDetailView({super.key, this.couponId});

  @override
  State<CouponDetailView> createState() => _CouponDetailViewState();
}

class _CouponDetailViewState extends State<CouponDetailView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic>? _couponData;
  bool _isLoading = true;
  bool _isUsed = false;
  bool _isCheckingUsage = true;

  @override
  void initState() {
    super.initState();
    if (widget.couponId != null) {
      _loadCouponData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCouponData() async {
    try {
      if (widget.couponId == null) return;
      
      final doc = await _firestore.collection('coupons').doc(widget.couponId!).get();
      if (doc.exists) {
        setState(() {
          _couponData = doc.data();
          _isLoading = false;
        });
        
        // 使用済みかチェック
        _checkCouponUsage();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('クーポンデータ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // クーポンの使用状況をチェック
  Future<void> _checkCouponUsage() async {
    try {
      final user = _auth.currentUser;
      if (user == null || widget.couponId == null) return;

      final couponDoc = await _firestore.collection('coupons').doc(widget.couponId!).get();
      if (couponDoc.exists) {
        final couponData = couponDoc.data()!;
        final usedUserIds = List<String>.from(couponData['usedUserIds'] ?? []);
        
        if (mounted) {
          setState(() {
            _isUsed = usedUserIds.contains(user.uid);
            _isCheckingUsage = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isUsed = false;
            _isCheckingUsage = false;
          });
        }
      }
    } catch (e) {
      print('クーポン使用状況チェックエラー: $e');
      if (mounted) {
        setState(() {
          _isCheckingUsage = false;
        });
      }
    }
  }

  Future<void> _useCoupon() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインが必要です'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (widget.couponId == null) return;

      // 使用済みかチェック
      if (_isUsed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('このクーポンは既に使用済みです'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 確認ポップアップを表示
      final shouldUse = await _showConfirmDialog();
      if (!shouldUse) return;

      // クーポンの使用済みユーザーリストに追加
      final couponDoc = await _firestore.collection('coupons').doc(widget.couponId!).get();
      if (couponDoc.exists) {
        final couponData = couponDoc.data()!;
        final usedUserIds = List<String>.from(couponData['usedUserIds'] ?? []);
        
        if (!usedUserIds.contains(user.uid)) {
          usedUserIds.add(user.uid);
          await _firestore.collection('coupons').doc(widget.couponId!).update({
            'usedUserIds': usedUserIds,
            'totalUsageCount': usedUserIds.length,
            'lastUsedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      setState(() {
        _isUsed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('クーポンを使用しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('クーポン使用に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 確認ポップアップを表示
  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.help_outline,
                color: const Color(0xFFFF6B35),
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                'クーポン使用確認',
                style: TextStyle(
                  fontSize: 18,
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
                '「${_couponData?['title'] ?? 'タイトルなし'}」',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'このクーポンを使用しますか？',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '使用後は再度使用できません',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'キャンセル',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                '使用する',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '期限不明';
    
    try {
      final date = timestamp.toDate();
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

  String _getDiscountText() {
    if (_couponData == null) return '';
    
    final discountType = _couponData!['discountType'] ?? '割引率';
    final discountValue = _couponData!['discountValue'] ?? '';
    
    if (discountType == '割引率') {
      return '$discountValue%OFF';
    } else if (discountType == '割引額') {
      return '${discountValue}円OFF';
    } else if (discountType == '固定価格') {
      return '${discountValue}円';
    }
    return '特典あり';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'クーポン詳細',
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
          : _couponData == null
              ? const Center(
                  child: Text(
                    'クーポンが見つかりません',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // クーポン画像
                      Container(
                        width: double.infinity,
                        height: 200,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: _couponData!['imageUrl'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  _couponData!['imageUrl'],
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.image,
                                      size: 80,
                                      color: Colors.grey,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey,
                              ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // クーポン情報
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
                            // タイトル
                            Text(
                              _couponData!['title'] ?? 'タイトルなし',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  
                            const SizedBox(height: 10),
                  
                            // 店舗名
                            Row(
                              children: [
                                const Icon(
                                  Icons.store,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _couponData!['storeName'] ?? '店舗名なし',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                  
                            const SizedBox(height: 15),
                  
                            // 期限
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _formatDate(_couponData!['endDate']),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                  
                            const SizedBox(height: 20),
                  
                            // 説明
                            const Text(
                              'クーポン詳細',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  
                            const SizedBox(height: 10),
                  
                            Text(
                              _couponData!['description'] ?? '説明がありません',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                  
                            const SizedBox(height: 30),
                  
                            // 利用条件
                            const Text(
                              '利用条件',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  
                            const SizedBox(height: 10),
                  
                            _buildConditionItem('割引内容：${_getDiscountText()}'),
                            if (_couponData!['conditions']?.isNotEmpty == true)
                              _buildConditionItem(_couponData!['conditions']),
                  
                            const SizedBox(height: 30),
                  
                            // 利用ボタン
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: (_isUsed || _isCheckingUsage) ? null : _useCoupon,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isUsed ? Colors.grey : const Color(0xFF1E88E5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: _isCheckingUsage
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _isUsed ? '使用済み（1回のみ使用可能）' : 'このクーポンを使用',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
    );
  }

  Widget _buildConditionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 