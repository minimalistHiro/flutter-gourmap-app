import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 紹介コード生成（8文字のランダム英数字）
  String generateReferralCode() {
    // 紛らわしい文字を除外（0, O, 1, I, l）
    const String chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final Random random = Random.secure(); // セキュアランダムを使用
    
    // より強力なランダム性のため、現在時刻のマイクロ秒も使用
    final int seed = DateTime.now().microsecondsSinceEpoch;
    final Random additionalRandom = Random(seed);
    
    return String.fromCharCodes(Iterable.generate(8, (index) {
      // 偶数位置は通常のランダム、奇数位置は追加ランダムを使用
      final randomToUse = index % 2 == 0 ? random : additionalRandom;
      return chars.codeUnitAt(randomToUse.nextInt(chars.length));
    }));
  }

  // ユーザーの紹介コードを取得または生成
  Future<String> getUserReferralCode(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (data.containsKey('referralCode') && data['referralCode'] != null) {
          return data['referralCode'];
        }
      }
      
      // 紹介コードが存在しない場合、新規生成
      String newCode;
      bool isUnique = false;
      int retryCount = 0;
      const int maxRetries = 50; // 最大50回まで試行
      
      print('新しい紹介コードを生成開始（ユーザー: $userId）');
      
      // ユニークなコードを生成するまで繰り返し
      do {
        retryCount++;
        newCode = generateReferralCode();
        
        print('紹介コード生成試行 $retryCount 回目: $newCode');
        
        // 重複チェック
        final existingCode = await _firestore
            .collection('users')
            .where('referralCode', isEqualTo: newCode)
            .limit(1) // パフォーマンス向上のため1件に制限
            .get();
        
        isUnique = existingCode.docs.isEmpty;
        
        if (!isUnique) {
          print('紹介コード $newCode は既に使用されています（試行回数: $retryCount）');
        } else {
          print('紹介コード $newCode はユニークです');
        }
        
        // 無限ループを防ぐため最大試行回数をチェック
        if (retryCount >= maxRetries) {
          throw Exception('紹介コードの生成に失敗しました。最大試行回数（$maxRetries回）に達しました。');
        }
        
      } while (!isUnique);
      
      // 最終的な重複チェックを実行
      final finalCheck = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: newCode)
          .limit(1)
          .get();
      
      if (finalCheck.docs.isNotEmpty) {
        throw Exception('最終チェックで紹介コード $newCode の重複が検出されました。再生成が必要です。');
      }

      // ユーザーに紹介コードを保存（トランザクションで安全に）
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('ユーザーが存在しません');
        }
        
        final userData = userDoc.data()!;
        
        // 既に他の処理で紹介コードが設定されていないかチェック
        if (userData.containsKey('referralCode') && userData['referralCode'] != null) {
          print('他の処理で既に紹介コードが設定されていました: ${userData['referralCode']}');
          // 既存のコードを返すために例外をスロー
          throw Exception('EXISTING_CODE:${userData['referralCode']}');
        }
        
        // 紹介コードを保存
        transaction.update(userRef, {
          'referralCode': newCode,
        });
        
        print('紹介コード $newCode をユーザー $userId に保存しました');
      });
      
      return newCode;
    } catch (e) {
      print('紹介コード取得エラー: $e');
      
      // 既存コードが見つかった場合の特別処理
      if (e.toString().contains('EXISTING_CODE:')) {
        final existingCode = e.toString().split('EXISTING_CODE:')[1];
        print('既存の紹介コードを返します: $existingCode');
        return existingCode;
      }
      
      throw Exception('紹介コードの取得に失敗しました: $e');
    }
  }

  // 紹介コードの検証
  Future<Map<String, dynamic>?> validateReferralCode(String code) async {
    try {
      if (code.trim().isEmpty) {
        print('紹介コード検証: 空のコードが入力されました');
        return null;
      }
      
      final trimmedCode = code.trim();
      print('紹介コード検証開始: $trimmedCode');
      
      // 8文字の英数字チェック
      final RegExp codePattern = RegExp(r'^[A-Za-z0-9]{8}$');
      if (!codePattern.hasMatch(trimmedCode)) {
        print('紹介コード検証: 無効な形式 ($trimmedCode)');
        return null;
      }
      
      final result = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: trimmedCode)
          .limit(1) // パフォーマンス向上のため1件に制限
          .get();
      
      if (result.docs.isNotEmpty) {
        final userData = result.docs.first.data();
        print('紹介コード検証成功: $trimmedCode -> ユーザー ${result.docs.first.id}');
        return {
          'userId': result.docs.first.id,
          'username': userData['username'] ?? '未設定',
          'email': userData['email'] ?? '',
        };
      }
      
      print('紹介コード検証: コード $trimmedCode に対応するユーザーが見つかりません');
      return null;
    } catch (e) {
      print('紹介コード検証エラー: $e');
      throw Exception('紹介コードの検証に失敗しました: $e');
    }
  }

  // 紹介処理（新規ユーザーがサインアップ時に呼び出し）
  Future<void> processReferral(String newUserId, String referralCode) async {
    try {
      // 紹介者情報を取得
      final referrerData = await validateReferralCode(referralCode);
      if (referrerData == null) {
        throw Exception('無効な紹介コードです');
      }
      
      final referrerId = referrerData['userId'];
      
      // 自分自身の紹介コードでないことを確認
      if (referrerId == newUserId) {
        throw Exception('自分の紹介コードは使用できません');
      }
      
      // トランザクションで紹介処理を実行
      await _firestore.runTransaction((transaction) async {
        // 紹介者と新規ユーザーのドキュメントを取得
        final referrerRef = _firestore.collection('users').doc(referrerId);
        final newUserRef = _firestore.collection('users').doc(newUserId);
        
        final referrerDoc = await transaction.get(referrerRef);
        final newUserDoc = await transaction.get(newUserRef);
        
        if (!referrerDoc.exists || !newUserDoc.exists) {
          throw Exception('ユーザー情報が見つかりません');
        }
        
        final referrerData = referrerDoc.data()!;
        final newUserData = newUserDoc.data()!;
        
        // 既に紹介処理が済んでいないかチェック
        if (newUserData.containsKey('referredBy') && newUserData['referredBy'] != null) {
          throw Exception('既に紹介処理が完了しています');
        }
        
        // 現在のポイント数を取得
        final referrerPoints = referrerData['points'] ?? 0;
        final newUserPoints = newUserData['points'] ?? 0;
        
        // 紹介者にポイント付与
        transaction.update(referrerRef, {
          'points': referrerPoints + 1000,
          'referralCount': (referrerData['referralCount'] ?? 0) + 1,
        });
        
        // 新規ユーザーにポイント付与と紹介者情報を記録
        transaction.update(newUserRef, {
          'points': newUserPoints + 1000,
          'referredBy': referrerId,
          'referredAt': FieldValue.serverTimestamp(),
        });
        
        // 紹介履歴を記録
        final referralHistoryRef = _firestore.collection('referral_history').doc();
        transaction.set(referralHistoryRef, {
          'referrerId': referrerId,
          'referrerName': referrerData['username'] ?? '未設定',
          'newUserId': newUserId,
          'newUserName': newUserData['username'] ?? '未設定',
          'referralCode': referralCode,
          'pointsAwarded': 1000,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      
      print('紹介処理完了: 紹介者($referrerId)と新規ユーザー($newUserId)に1000ptずつ付与');
    } catch (e) {
      print('紹介処理エラー: $e');
      rethrow;
    }
  }

  // 紹介履歴を取得
  Future<List<Map<String, dynamic>>> getReferralHistory(String userId) async {
    try {
      final result = await _firestore
          .collection('referral_history')
          .where('referrerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return result.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'newUserName': data['newUserName'] ?? '未設定',
          'pointsAwarded': data['pointsAwarded'] ?? 0,
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      print('紹介履歴取得エラー: $e');
      return [];
    }
  }

  // 紹介統計を取得
  Future<Map<String, int>> getReferralStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      
      final referralCount = userData['referralCount'] ?? 0;
      final totalPointsEarned = referralCount * 1000; // 1紹介=1000pt
      
      return {
        'referralCount': referralCount,
        'totalPointsEarned': totalPointsEarned,
      };
    } catch (e) {
      print('紹介統計取得エラー: $e');
      return {
        'referralCount': 0,
        'totalPointsEarned': 0,
      };
    }
  }
}