import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'referral_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReferralService _referralService = ReferralService();

  // 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  // 認証状態の変更を監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // メールアドレスとパスワードでサインアップ
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    int? age,
    String? address,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ユーザー情報をFirestoreに保存
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'age': age,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
        'points': 0,
        'stamps': 0,
        'rank': 'ブロンズ',
        'isStoreOwner': false, // 店舗アカウントか否かのステータスを追加
        'goldStamps': 0, // ゴールドスタンプ数を追加
        'paid': 0, // 総支払額を追加
        'readNotifications': [], // 既読通知リストを追加
        'accountType': 'email', // アカウント作成方法を追加
      });
      
      // 紹介コードを生成して保存
      try {
        final referralCode = await _referralService.getUserReferralCode(userCredential.user!.uid);
        print('新規ユーザーの紹介コード生成完了: $referralCode');
      } catch (e) {
        print('紹介コード生成エラー（非致命的）: $e');
      }

      return userCredential;
    } catch (e) {
      throw Exception('サインアップに失敗しました: $e');
    }
  }

  // メールアドレスとパスワードでサインイン
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // ログイン後、紹介コードが存在しない場合は生成
      try {
        await _referralService.getUserReferralCode(userCredential.user!.uid);
        print('ログインユーザーの紹介コードチェック完了');
      } catch (e) {
        print('ログイン時の紹介コードチェックエラー（非致命的）: $e');
      }
      
      return userCredential;
    } catch (e) {
      throw Exception('サインインに失敗しました: $e');
    }
  }

  // サインアウト
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('サインアウトに失敗しました: $e');
    }
  }

  // パスワードリセット
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('パスワードリセットに失敗しました: $e');
    }
  }

  // ユーザー情報を更新
  Future<void> updateUserProfile({
    required String username,
    String? bio,
  }) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'username': username,
          'bio': bio,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('プロフィール更新に失敗しました: $e');
    }
  }

  // ユーザー情報を取得
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      throw Exception('ユーザー情報の取得に失敗しました: $e');
    }
  }

  // 既存ユーザーに店舗アカウントステータスを追加
  Future<void> addStoreOwnerStatusToExistingUsers() async {
    try {
      // 全てのユーザーを取得
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      for (DocumentSnapshot userDoc in usersSnapshot.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        // 必要なフィールドが存在しない場合のみ追加
        Map<String, dynamic> updates = {};
        
        if (!userData.containsKey('isStoreOwner')) {
          updates['isStoreOwner'] = false;
        }
        
        if (!userData.containsKey('goldStamps')) {
          updates['goldStamps'] = 0;
        }
        
        if (!userData.containsKey('paid')) {
          updates['paid'] = 0;
        }
        
        if (!userData.containsKey('readNotifications')) {
          updates['readNotifications'] = [];
        }
        
        // 更新が必要な場合のみ実行
        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(userDoc.id).update(updates);
          print('ユーザー ${userDoc.id} に店舗アカウントステータスを追加しました');
        }
      }
      
      print('既存ユーザーへの店舗アカウントステータス追加が完了しました');
    } catch (e) {
      print('既存ユーザーへの店舗アカウントステータス追加に失敗しました: $e');
      throw Exception('既存ユーザーへの店舗アカウントステータス追加に失敗しました: $e');
    }
  }

  // 店舗アカウントステータスを更新
  Future<void> updateStoreOwnerStatus(bool isStoreOwner) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isStoreOwner': isStoreOwner,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('店舗アカウントステータスの更新に失敗しました: $e');
    }
  }

  // パスワードで再認証
  Future<UserCredential?> reauthenticateWithPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      return await currentUser?.reauthenticateWithCredential(credential);
    } catch (e) {
      print('再認証に失敗しました: $e');
      return null;
    }
  }

  // ユーザーのメールアドレスを更新
  Future<void> updateUserEmail(String newEmail) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'email': newEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Firestoreのメールアドレス更新に失敗しました: $e');
    }
  }

  // Googleサインイン
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Web環境チェック
      if (kIsWeb) {
        // Web用のGoogle Sign-In
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        // Firebase Auth経由でGoogle認証
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        
        // 新規ユーザーの場合、Firestoreにユーザー情報を保存
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await _createUserDocument(
            userCredential.user!,
            'google',
            userCredential.user!.displayName ?? 'Google User',
            userCredential.user!.email,
          );
        }
        
        return userCredential;
      } else {
        // モバイル用のGoogle Sign-In
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        
        if (googleUser == null) {
          return null; // ユーザーがサインインをキャンセルした場合
        }

        // Google認証の詳細を取得
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Firebase用の認証情報を作成
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Firebaseでサインイン
        final UserCredential userCredential = await _auth.signInWithCredential(credential);

        // 新規ユーザーの場合、Firestoreにユーザー情報を保存
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await _createUserDocument(
            userCredential.user!,
            'google',
            googleUser.displayName ?? 'Google User',
            googleUser.email,
          );
        }

        return userCredential;
      }
    } catch (e) {
      print('Googleサインインエラー: $e');
      if (e.toString().contains('popup_closed_by_user')) {
        throw Exception('Googleサインインがキャンセルされました');
      } else if (e.toString().contains('network_error')) {
        throw Exception('ネットワークエラーが発生しました。インターネット接続を確認してください');
      } else if (e.toString().contains('Client ID')) {
        throw Exception('Google認証の設定に問題があります。しばらく時間をおいてから再度お試しください');
      } else if (e.toString().contains('operation-not-allowed')) {
        throw Exception('Google認証が管理者によって無効にされています。現在はメールアドレスでの登録・ログインをご利用ください');
      } else {
        throw Exception('Googleサインインに失敗しました。しばらく時間をおいてから再度お試しください');
      }
    }
  }

  // Apple Sign Inサインイン
  Future<UserCredential?> signInWithApple() async {
    try {
      if (kIsWeb) {
        // Web環境では一旦Apple Sign-Inを無効化
        throw Exception('Web版のApple Sign Inは現在準備中です。メールアドレスでの登録・ログインをご利用ください');
      } else {
        // モバイル用のApple Sign-In
        // Apple Sign Inが利用可能かチェック
        if (!await SignInWithApple.isAvailable()) {
          throw Exception('Apple Sign Inは現在のデバイスでは利用できません');
        }

        // nonceを生成
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);

        // Apple Sign In認証リクエスト
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        // OAuth認証情報を作成
        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );

        // Firebaseでサインイン
        final UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);

        // 新規ユーザーの場合、Firestoreにユーザー情報を保存
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          final displayName = appleCredential.givenName != null && appleCredential.familyName != null
              ? '${appleCredential.givenName} ${appleCredential.familyName}'
              : 'Apple User';
          
          await _createUserDocument(
            userCredential.user!,
            'apple',
            displayName,
            appleCredential.email ?? userCredential.user!.email,
          );
        }

        return userCredential;
      }
    } catch (e) {
      print('Apple Sign Inエラー: $e');
      if (e.toString().contains('popup_closed_by_user')) {
        throw Exception('Apple Sign Inがキャンセルされました');
      } else if (e.toString().contains('network_error')) {
        throw Exception('ネットワークエラーが発生しました。インターネット接続を確認してください');
      } else if (e.toString().contains('not supported')) {
        throw Exception('Apple Sign Inは現在のブラウザではサポートされていません');
      } else if (e.toString().contains('operation-not-allowed')) {
        throw Exception('Apple Sign Inが管理者によって無効にされています。現在はメールアドレスでの登録・ログインをご利用ください');
      } else if (e.toString().contains('準備中')) {
        // 再スローして元のメッセージを保持
        rethrow;
      } else {
        throw Exception('Apple Sign Inに失敗しました。しばらく時間をおいてから再度お試しください');
      }
    }
  }

  // ユーザードキュメントをFirestoreに作成
  Future<void> _createUserDocument(
    User user,
    String accountType,
    String displayName,
    String? email, {
    String? referralCode,
  }) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'username': displayName,
        'email': email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'points': 0,
        'stamps': 0,
        'rank': 'ブロンズ',
        'isStoreOwner': false,
        'goldStamps': 0,
        'totalPaid': 0,
        'readNotifications': [],
        'accountType': accountType, // 'google', 'apple', 'email'のいずれか
        'isOwner': false, // オーナーフラグ
        'showTutorial': true, // 新規ユーザーにはチュートリアル表示フラグをtrue
      });
      
      // 紹介コード処理
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        try {
          print('紹介コード処理開始(Social): $referralCode');
          await _referralService.processReferral(user.uid, referralCode.trim());
          print('紹介コード処理成功(Social)');
        } catch (referralError) {
          print('紹介コード処理エラー(Social): $referralError');
          // 紹介エラーは致命的ではないので、継続
        }
      }
    } catch (e) {
      print('ユーザードキュメント作成エラー: $e');
      throw Exception('ユーザー情報の保存に失敗しました: $e');
    }
  }

  // nonceを生成
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // SHA256ハッシュを生成
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
} 