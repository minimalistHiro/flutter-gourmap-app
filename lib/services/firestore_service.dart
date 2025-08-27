import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ユーザーのポイント履歴を取得
  Future<List<Map<String, dynamic>>> getPointHistory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('pointHistory')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('ポイント履歴の取得に失敗しました: $e');
    }
  }

  // ポイント履歴を追加
  Future<void> addPointHistory({
    required String userId,
    required int points,
    required String type,
    required String description,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('pointHistory')
          .add({
        'points': points,
        'type': type, // 'earn', 'spend', 'bonus'
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ユーザーの総ポイントを更新
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(points),
      });
    } catch (e) {
      throw Exception('ポイント履歴の追加に失敗しました: $e');
    }
  }

  // スタンプ情報を取得
  Future<List<Map<String, dynamic>>> getStampHistory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stamps')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('スタンプ履歴の取得に失敗しました: $e');
    }
  }

  // スタンプを追加
  Future<void> addStamp({
    required String userId,
    required String storeName,
    required String description,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stamps')
          .add({
        'storeName': storeName,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ユーザーの総スタンプ数を更新
      await _firestore.collection('users').doc(userId).update({
        'stamps': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('スタンプの追加に失敗しました: $e');
    }
  }

  // 投稿を取得
  Future<List<Map<String, dynamic>>> getPosts({int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('投稿の取得に失敗しました: $e');
    }
  }

  // 投稿を追加
  Future<void> addPost({
    required String userId,
    required String content,
    required List<String> imageUrls,
    String? storeName,
    String? location,
  }) async {
    try {
      await _firestore.collection('posts').add({
        'userId': userId,
        'content': content,
        'imageUrls': imageUrls,
        'storeName': storeName,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
      });
    } catch (e) {
      throw Exception('投稿の追加に失敗しました: $e');
    }
  }

  // クーポンを取得
  Future<List<Map<String, dynamic>>> getCoupons({int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('coupons')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('クーポンの取得に失敗しました: $e');
    }
  }

  // クーポンを追加
  Future<String> addCoupon({
    required String userId,
    required String title,
    required String description,
    required String discountType,
    required String discountValue,
    required DateTime startDate,
    required DateTime endDate,
    required TimeOfDay endTime,
    required String conditions,
    String? imageUrl,
    String? storeId,
    String? storeName,
    int maxUsagePerUser = 1,
  }) async {
    try {
      // 終了日時を結合
      final endDateTime = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        endTime.hour,
        endTime.minute,
      );

      DocumentReference docRef = await _firestore.collection('coupons').add({
        'userId': userId,
        'title': title,
        'description': description,
        'discountType': discountType,
        'discountValue': discountValue,
        'startDate': startDate,
        'endDate': endDateTime,
        'imageUrl': imageUrl,
        'conditions': conditions,
        'storeId': storeId,
        'storeName': storeName,
        'maxUsagePerUser': maxUsagePerUser,
        'usedUserIds': [], // 使用済みユーザーIDのリスト
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'totalUsageCount': 0,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('クーポンの追加に失敗しました: $e');
    }
  }

  // ユーザーが作成したクーポンを取得
  Future<List<Map<String, dynamic>>> getUserCoupons(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('coupons')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('ユーザークーポンの取得に失敗しました: $e');
    }
  }

  // クーポンが使用済みかチェック
  Future<bool> isCouponUsed(String couponId, String userId) async {
    try {
      final couponDoc = await _firestore.collection('coupons').doc(couponId).get();
      if (!couponDoc.exists) return false;
      
      final couponData = couponDoc.data()!;
      final usedUserIds = List<String>.from(couponData['usedUserIds'] ?? []);
      
      return usedUserIds.contains(userId);
    } catch (e) {
      print('クーポン使用状況チェックエラー: $e');
      return false;
    }
  }

  // クーポンを使用済みとしてマーク
  Future<void> markCouponAsUsed(String couponId, String userId) async {
    try {
      // 既に使用済みかチェック
      final isAlreadyUsed = await isCouponUsed(couponId, userId);
      if (isAlreadyUsed) {
        throw Exception('このクーポンは既に使用済みです');
      }

      // クーポンの使用制限をチェック
      final couponDoc = await _firestore.collection('coupons').doc(couponId).get();
      if (!couponDoc.exists) {
        throw Exception('クーポンが見つかりません');
      }

      final couponData = couponDoc.data()!;
      final maxUsagePerUser = couponData['maxUsagePerUser'] ?? 1;
      final usedUserIds = List<String>.from(couponData['usedUserIds'] ?? []);
      
      // 現在の使用ユーザー数をチェック
      if (usedUserIds.length >= maxUsagePerUser) {
        throw Exception('このクーポンの使用上限に達しています');
      }

      // クーポンの使用済みユーザーリストに追加
      usedUserIds.add(userId);
      await _firestore.collection('coupons').doc(couponId).update({
        'usedUserIds': usedUserIds,
        'totalUsageCount': usedUserIds.length,
        'lastUsedAt': FieldValue.serverTimestamp(),
      });

      // 使用履歴も記録（オプション）
      try {
        await _firestore
            .collection('coupon_usage_history')
            .add({
          'couponId': couponId,
          'userId': userId,
          'usedAt': FieldValue.serverTimestamp(),
          'couponTitle': couponData['title'] ?? 'タイトルなし',
          'storeName': couponData['storeName'] ?? '店舗名なし',
        });
      } catch (e) {
        // 履歴記録に失敗しても、クーポン使用は成功とする
        print('使用履歴記録に失敗しました: $e');
      }

      print('クーポン使用マーク完了: $couponId for user $userId');
    } catch (e) {
      throw Exception('クーポン使用マークに失敗しました: $e');
    }
  }

  // ユーザーのクーポン使用履歴を取得
  Future<List<Map<String, dynamic>>> getUserCouponUsage(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('coupon_usage')
          .where('userId', isEqualTo: userId)
          .orderBy('usedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'usageId': doc.id,
          'couponId': data['couponId'],
          'couponTitle': data['couponTitle'] ?? 'タイトルなし',
          'storeName': data['storeName'] ?? '店舗名なし',
          'usedAt': data['usedAt'],
        };
      }).toList();
    } catch (e) {
      throw Exception('クーポン使用履歴の取得に失敗しました: $e');
    }
  }

  // クーポンの画像URLを更新
  Future<void> updateCouponImage(String couponId, String imageUrl) async {
    try {
      await _firestore.collection('coupons').doc(couponId).update({
        'imageUrl': imageUrl,
      });
    } catch (e) {
      throw Exception('クーポン画像URLの更新に失敗しました: $e');
    }
  }

  // 店舗情報を取得
  Future<List<Map<String, dynamic>>> getStores({int limit = 50}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('stores')
          .orderBy('name')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('店舗情報の取得に失敗しました: $e');
    }
  }

  // ランキング情報を取得
  Future<List<Map<String, dynamic>>> getRankings() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .orderBy('points', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('ランキングの取得に失敗しました: $e');
    }
  }
} 