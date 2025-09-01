import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 紹介コード生成（8文字のランダム英数字、大文字・小文字・数字）
  String generateReferralCode() {
    // 紛らわしい文字を除外（0, O, o, 1, I, l）
    const String chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
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
  
  // テスト用の簡単な紹介コード生成（デバッグ用）
  String generateTestReferralCode() {
    // テスト用に簡単なコードを生成
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random();
    
    return String.fromCharCodes(Iterable.generate(8, (_) =>
        chars.codeUnitAt(random.nextInt(chars.length))));
  }
  
  // 特定の紹介コードを強制的に作成（テスト用）
  Future<String> createTestReferralCode(String userId, {String? specificCode}) async {
    try {
      final testCode = specificCode ?? 'TEST1234';
      print('テスト用紹介コード作成: $testCode for ユーザー $userId');
      
      await _firestore.collection('users').doc(userId).update({
        'referralCode': testCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('テスト用紹介コード作成完了: $testCode');
      return testCode;
    } catch (e) {
      print('テスト用紹介コード作成エラー: $e');
      throw Exception('テスト用紹介コードの作成に失敗しました: $e');
    }
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
      
      final trimmedCode = code.trim(); // 大文字小文字をそのまま保持
      print('=== 紹介コード検証詳細ログ ===');
      print('入力コード: "$trimmedCode"');
      print('コード長: ${trimmedCode.length}');
      print('先頭文字: ${trimmedCode.isNotEmpty ? trimmedCode[0] : "なし"}');
      print('末尾文字: ${trimmedCode.isNotEmpty ? trimmedCode[trimmedCode.length - 1] : "なし"}');
      
      // 8文字の英数字チェック（大文字・小文字・数字対応）
      final RegExp codePattern = RegExp(r'^[A-Za-z0-9]{8}$');
      final isValidFormat = codePattern.hasMatch(trimmedCode);
      print('形式チェック結果: $isValidFormat');
      
      if (!isValidFormat) {
        print('紹介コード検証: 無効な形式 ($trimmedCode)');
        // 長さが異なる場合の詳細チェック
        if (trimmedCode.length != 8) {
          print('エラー: コード長が8文字ではありません (実際: ${trimmedCode.length})');
        }
        return null;
      }
      
      print('Firestoreクエリ実行中...');
      
      // まず全ユーザーの紹介コードをデバッグ表示
      await _debugPrintAllReferralCodes();
      
      // 大文字小文字を区別しないクエリを実行
      final result = await _firestore
          .collection('users')
          .get(); // 全件取得してクライアントサイドでフィルタリング
      
      print('全ユーザー数: ${result.docs.length}');
      
      // クライアントサイドで完全一致検索（大文字小文字を区別する）
      final matchingDocs = result.docs.where((doc) {
        final data = doc.data();
        final userReferralCode = data['referralCode']?.toString();
        return userReferralCode == trimmedCode;
      }).toList();
      
      print('マッチしたユーザー数: ${matchingDocs.length}');
      
      if (matchingDocs.isNotEmpty) {
        final userData = matchingDocs.first.data();
        final userId = matchingDocs.first.id;
        print('紹介コード検証成功: $trimmedCode -> ユーザー $userId (${userData['username']})');
        return {
          'uid': userId,
          'userId': userId,  // 後方互換性のため
          'username': userData['username'] ?? '未設定',
          'email': userData['email'] ?? '',
          'referralCode': trimmedCode,
        };
      }
      
      print('紹介コード検証: コード $trimmedCode に対応するユーザーが見つかりません');
      return null;
    } catch (e) {
      print('紹介コード検証エラー: $e');
      print('エラースタックトレース: ${e.toString()}');
      throw Exception('紹介コードの検証に失敗しました: $e');
    }
  }
  
  // デバッグ用：全ユーザーの紹介コードを表示
  Future<void> _debugPrintAllReferralCodes() async {
    try {
      print('=== 全ユーザーの紹介コード一覧（デバッグ用） ===');
      final allUsersSnapshot = await _firestore
          .collection('users')
          .get();
      
      int codeCount = 0;
      for (final doc in allUsersSnapshot.docs) {
        final data = doc.data();
        final referralCode = data['referralCode'];
        final username = data['username'];
        final userId = doc.id;
        
        if (referralCode != null) {
          codeCount++;
          print('[$codeCount] ユーザーID: $userId, ユーザー名: $username, 紹介コード: "$referralCode"');
        } else {
          print('紹介コードなし - ユーザーID: $userId, ユーザー名: $username');
        }
      }
      print('=== 紹介コード一覧終了（有効コード数: $codeCount） ===');
    } catch (e) {
      print('デバッグ用クエリエラー: $e');
    }
  }

  // 紹介処理（新規ユーザーがサインアップ時に呼び出し）
  Future<Map<String, dynamic>> processReferral(String newUserId, String referralCode) async {
    try {
      // 紹介者情報を取得
      final referrerData = await validateReferralCode(referralCode);
      if (referrerData == null) {
        throw Exception('無効な紹介コードです');
      }
      
      final referrerId = referrerData['uid'] ?? referrerData['userId'];
      
      // 自分自身の紹介コードでないことを確認
      if (referrerId == newUserId) {
        throw Exception('自分の紹介コードは使用できません');
      }
      
      String? notificationId;
      Map<String, dynamic>? referrerDataFull;
      Map<String, dynamic>? newUserData;
      
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
        
        referrerDataFull = referrerDoc.data()!;
        newUserData = newUserDoc.data()!;
        
        // 既に紹介処理が済んでいないかチェック
        if (newUserData!.containsKey('referredBy') && newUserData!['referredBy'] != null) {
          throw Exception('既に紹介処理が完了しています');
        }
        
        // 紹介履歴で重複チェック
        final existingReferralQuery = await _firestore
            .collection('referral_history')
            .where('newUserId', isEqualTo: newUserId)
            .limit(1)
            .get();
        
        if (existingReferralQuery.docs.isNotEmpty) {
          throw Exception('この新規ユーザーは既に紹介処理が完了しています');
        }
        
        // 現在のポイント数を取得
        final newUserPoints = newUserData!['points'] ?? 0;
        
        // 新規ユーザーに即座にポイント付与と紹介者情報を記録
        transaction.update(newUserRef, {
          'points': newUserPoints + 1000,
          'referredBy': referrerId,
          'referredAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // 新規ユーザーのポイント履歴を記録
        final newUserPointHistoryRef = _firestore.collection('point_history').doc();
        transaction.set(newUserPointHistoryRef, {
          'userId': newUserId,
          'type': 'referral_bonus',
          'amount': 1000,
          'description': '友達紹介ボーナス（${referrerDataFull!['username'] ?? 'ユーザー'}の紹介コード使用）',
          'relatedUserId': referrerId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed',
        });
        
        // 紹介履歴を記録（通知IDは後で更新）
        final referralHistoryRef = _firestore.collection('referral_history').doc();
        transaction.set(referralHistoryRef, {
          'referrerId': referrerId,
          'referrerName': referrerDataFull!['username'] ?? '未設定',
          'newUserId': newUserId,
          'newUserName': newUserData!['username'] ?? '未設定',
          'referralCode': referralCode,
          'pointsAwarded': 1000,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'new_user_completed', // 新規ユーザーのみ完了
          'notificationId': null, // 後で更新
        });
      });
      
      // トランザクション外で通知を作成
      if (referrerDataFull != null && newUserData != null) {
        try {
          final notificationRef = _firestore.collection('notifications').doc();
          notificationId = notificationRef.id;
          
          await notificationRef.set({
            'title': '友達紹介成功！',
            'content': '${newUserData!['username'] ?? '新規ユーザー'}さんがあなたの紹介コードで登録しました。\n下のボタンを押して1000ポイントを受け取ってください。',
            'type': 'referral_reward',
            'category': '紹介報酬',
            'priority': '高',
            'isActive': true,
            'isPublished': true,
            'isOwnerOnly': false,
            'targetUserId': referrerId, // 通知の対象ユーザー
            'referralData': {
              'newUserId': newUserId,
              'newUserName': newUserData!['username'] ?? '新規ユーザー',
              'referralCode': referralCode,
              'pointsToAward': 1000,
              'isPointsClaimed': false,
            },
            'createdAt': FieldValue.serverTimestamp(),
            'publishedAt': FieldValue.serverTimestamp(),
            'userId': 'system',
            'username': 'システム',
            'userEmail': 'system@groumap.com',
          });
          
          print('紹介者への通知作成完了: $notificationId');
        } catch (e) {
          print('通知作成エラー: $e');
          // 通知作成に失敗してもメイン処理は続行
        }
      }
      
      print('紹介処理完了: 新規ユーザー($newUserId)に1000pt付与、紹介者($referrerId)に通知送信');
      
      return {
        'success': true,
        'pointsEarned': 1000,
        'referrerName': referrerData['username'],
        'notificationId': notificationId,
      };
    } catch (e) {
      print('紹介処理エラー: $e');
      rethrow;
    }
  }

  // 紹介報酬を受け取る（紹介者用）
  Future<Map<String, dynamic>> claimReferralReward(String notificationId, String userId) async {
    try {
      Map<String, dynamic> result = {};
      
      await _firestore.runTransaction((transaction) async {
        // 通知ドキュメントを取得
        final notificationRef = _firestore.collection('notifications').doc(notificationId);
        final notificationDoc = await transaction.get(notificationRef);
        
        if (!notificationDoc.exists) {
          throw Exception('通知が見つかりません');
        }
        
        final notificationData = notificationDoc.data()!;
        
        // 通知の種類とターゲットユーザーをチェック
        if (notificationData['type'] != 'referral_reward') {
          throw Exception('この通知は紹介報酬ではありません');
        }
        
        if (notificationData['targetUserId'] != userId) {
          throw Exception('この報酬を受け取る権限がありません');
        }
        
        final referralData = notificationData['referralData'] as Map<String, dynamic>;
        
        // 既に受け取り済みかチェック
        if (referralData['isPointsClaimed'] == true) {
          throw Exception('既にポイントを受け取り済みです');
        }
        
        // ユーザーの現在のポイントを取得
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('ユーザー情報が見つかりません');
        }
        
        final userData = userDoc.data()!;
        final currentPoints = userData['points'] ?? 0;
        final pointsToAward = referralData['pointsToAward'] ?? 1000;
        
        // ユーザーにポイントを付与
        transaction.update(userRef, {
          'points': currentPoints + pointsToAward,
          'referralCount': (userData['referralCount'] ?? 0) + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // ポイント履歴を記録
        final pointHistoryRef = _firestore.collection('point_history').doc();
        transaction.set(pointHistoryRef, {
          'userId': userId,
          'type': 'referral_reward',
          'amount': pointsToAward,
          'description': '友達紹介ボーナス（${referralData['newUserName']}を紹介）',
          'relatedUserId': referralData['newUserId'],
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed',
        });
        
        // 通知を受け取り済み状態に更新
        transaction.update(notificationRef, {
          'referralData.isPointsClaimed': true,
          'referralData.claimedAt': FieldValue.serverTimestamp(),
          'title': '友達紹介報酬 - 受け取り済み',
          'content': '${referralData['newUserName']}さんの紹介報酬として${pointsToAward}ポイントを受け取りました。',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // 紹介履歴を更新
        final referralHistoryQuery = await _firestore
            .collection('referral_history')
            .where('notificationId', isEqualTo: notificationId)
            .limit(1)
            .get();
        
        if (referralHistoryQuery.docs.isNotEmpty) {
          final historyRef = referralHistoryQuery.docs.first.reference;
          transaction.update(historyRef, {
            'status': 'completed',
            'referrerPointsClaimed': true,
            'referrerPointsClaimedAt': FieldValue.serverTimestamp(),
          });
        }
        
        result = {
          'success': true,
          'pointsEarned': pointsToAward,
          'newUserName': referralData['newUserName'],
          'totalPoints': currentPoints + pointsToAward,
        };
      });
      
      print('紹介報酬受け取り完了: ユーザー($userId)が${result['pointsEarned']}pt受け取り');
      return result;
    } catch (e) {
      print('紹介報酬受け取りエラー: $e');
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

  // 新規ユーザー用ポップアップ表示（サインアップ後に呼び出し）
  static Future<void> showNewUserReferralBonus(
    BuildContext context, 
    Map<String, dynamic> referralResult
  ) async {
    if (referralResult['success'] != true) return;

    final pointsEarned = referralResult['pointsEarned'] ?? 1000;
    final referrerName = referralResult['referrerName'] ?? 'ユーザー';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'ようこそ！',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '友達紹介ボーナス',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/point_icon.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.monetization_on,
                            color: Color(0xFFFF6B35),
                            size: 32,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+$pointsEarned',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      const Text(
                        'pt',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$referrerNameさんの紹介でGourMapに参加いただき、\nありがとうございます！',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ポイントはお店で商品やサービスと\n交換できます。\nGourMapをお楽しみください！',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                '始める',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}