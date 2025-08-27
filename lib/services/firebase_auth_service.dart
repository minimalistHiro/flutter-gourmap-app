import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      });

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
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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
} 