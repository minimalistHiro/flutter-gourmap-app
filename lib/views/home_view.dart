import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'notification_list_view.dart';

import 'entry_views/login_view.dart';
import 'menu_views/point_history_view.dart';
import 'menu_views/stamp_view.dart';
import 'menu_views/friend_intro_view.dart';
import 'menu_views/store_list_view.dart';
import 'post_detail_view.dart';
import 'coupon_detail_view.dart';
import 'rank_detail_view.dart';
import 'qr_code_views/qr_code_view.dart';
import 'menu_views/ranking_list_view.dart';
import 'feedback_view.dart';
import 'entry_views/tutorial_view.dart';
import 'slot_machine_view.dart';

class HomeView extends StatefulWidget {
  final int selectedTab;
  final bool isShowCouponView;
  final Function(int) onTabChanged;
  final Function(bool) onCouponViewChanged;

  const HomeView({
    super.key,
    required this.selectedTab,
    required this.isShowCouponView,
    required this.onTabChanged,
    required this.onCouponViewChanged,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

// HomeViewのデータ再読み込み用のコールバック
typedef HomeViewRefreshCallback = void Function();
HomeViewRefreshCallback? homeViewRefreshCallback;

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  bool isShowLoginView = false;
  bool isShowSignUpView = false;
  bool isShowRouletteView = false;
  bool isBright = false;
  int paid = 10000;
  int goldStamps = 10;        // ゴールドスタンプ
  int points = 0; // ポイントを追加
  bool isLogin = false;
  double brightness = 0.5; // デフォルト輝度
  int selectedSlide = 1;
  List<int> pages = [1, 2, 3, 4];
  late AnimationController _slideController;
  late AnimationController _indicatorController;
  
  // Firebase関連
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 未読通知の状態
  bool _hasUnreadNotifications = false;
  
  // 投稿データ
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingPosts = true;
  
  // クーポンデータ
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoadingCoupons = true;
  
  // スロットの表示状態
  bool _isSlotAvailable = true;
  
  // スロット履歴のキャッシュ
  List<Map<String, dynamic>> _slotHistory = [];
  
  // 画像読み込み用のメソッド（CORS問題対応）
  Future<Uint8List?> _loadImageFromUrl(String imageUrl) async {
    try {
      // 方法1: HTTPリクエストで画像を取得
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'Accept': 'image/*',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );
      
      if (response.statusCode == 200) {
        print('方法1成功: HTTPリクエストで画像取得完了');
        return response.bodyBytes;
      } else {
        print('方法1失敗: HTTPステータス ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('方法1でエラー: $e');
      
      // 方法2: プロキシ経由での取得を試行（CORS回避）
      try {
        print('方法2: プロキシ経由での画像取得を試行');
        final proxyUrl = 'https://cors-anywhere.herokuapp.com/$imageUrl';
        final proxyResponse = await http.get(
          Uri.parse(proxyUrl),
          headers: {
            'Accept': 'image/*',
            'Origin': 'https://your-app-domain.com',
          },
        );
        
        if (proxyResponse.statusCode == 200) {
          print('方法2成功: プロキシ経由で画像取得完了');
          return proxyResponse.bodyBytes;
        } else {
          print('方法2失敗: プロキシステータス ${proxyResponse.statusCode}');
          return null;
        }
      } catch (proxyError) {
        print('方法2でエラー: $proxyError');
        return null;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    
    // データ再読み込み用のコールバックを登録
    homeViewRefreshCallback = _refreshAllData;
    
    _slideController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _startSlideTime();
    
    // 初期データ読み込み
    _initializeData();
  }
  
  // 初期データ読み込み
  Future<void> _initializeData() async {
    // まずユーザー認証状態を確認
    final user = _auth.currentUser;
    if (user == null) {
      print('ユーザーが未ログインのため、一部データの読み込みをスキップします');
      // 未ログイン時は投稿とクーポンのみ読み込み
      await Future.wait([
        _loadPosts(),
        _loadCoupons(),
      ]);
      return;
    }
    
    print('ユーザーログイン済み (${user.uid})、全データを読み込み開始');
    
    // 並列でデータを読み込み（順序依存のないもの）
    await Future.wait([
      _loadPosts(),
      _loadCoupons(),
      _loadUserData(user.uid), // 新しいメソッドで確実にユーザーデータを取得
      _loadSlotHistory(user.uid), // スロット履歴を事前に読み込み
    ]);
    
    // ユーザーデータ読み込み後にスロット可用性チェック
    await _checkSlotAvailability();
    
    // ユーザー情報の監視を開始
    _listenToUserData();
    
    // 未読通知の監視を開始
    _listenToUnreadNotifications();
    
    // 既存ユーザーにisOwnerフィールドを追加
    _addOwnerFieldToExistingUsers();
  }

  @override
  void dispose() {
    // コールバックをクリア
    if (homeViewRefreshCallback == _refreshAllData) {
      homeViewRefreshCallback = null;
    }
    
    _slideController.dispose();
    _indicatorController.dispose();
    super.dispose();
  }
  
  // 全データを再読み込み
  Future<void> _refreshAllData() async {
    if (!mounted) return;
    
    print('HomeView: データ再読み込み開始');
    
    try {
      // すべてのデータを再読み込み
      await _initializeData();
      print('HomeView: データ再読み込み完了');
    } catch (e) {
      print('HomeView: データ再読み込みエラー: $e');
    }
  }

  void _startSlideTime() {
    _slideController.repeat();
    _slideController.addListener(() {
      if (_slideController.value >= 1.0) {
        if (mounted) {
          setState(() {
            selectedSlide = (selectedSlide % pages.length) + 1;
          });
        }
        _slideController.reset();
      }
    });
  }

  void _stopTime() {
    _slideController.stop();
  }
  
  // 未読通知の監視
  void _listenToUnreadNotifications() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // ユーザーがログインしている場合、通知と既読状態を監視
        _checkUnreadNotifications(user.uid);
        
        // ユーザーの既読状態の変更を監視
        _firestore.collection('users').doc(user.uid).snapshots().listen((snapshot) {
          if (snapshot.exists && mounted) {
            _checkUnreadNotifications(user.uid);
          }
        });
      } else {
        // ユーザーがログインしていない場合は未読状態をリセット
        if (mounted) {
          setState(() {
            _hasUnreadNotifications = false;
          });
        }
      }
    });
  }
  
  // 投稿データの読み込み
  Future<void> _loadPosts() async {
    try {
      print('投稿読み込み開始');
      
      // まず、シンプルに全ての投稿を取得
      final postsSnapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      print('取得した投稿数: ${postsSnapshot.docs.length}');
      
      // 各投稿のデータを確認
      for (final doc in postsSnapshot.docs) {
        final data = doc.data();
        print('投稿ID: ${doc.id}, データ: $data');
      }

      if (mounted) {
        setState(() {
          _posts = postsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'postId': data['postId'] ?? doc.id,
              'title': data['title'] ?? 'タイトルなし',
              'content': data['content'] ?? '',
              'storeName': data['storeName'] ?? '店舗名なし',
              'category': data['category'] ?? 'お知らせ',
              'createdAt': data['createdAt'],
              'imageUrls': data['imageUrls'] ?? [],
              'images': data['images'] ?? [], // 旧形式との互換性
              'imageCount': data['imageCount'] ?? 0,
              'storeIconImageUrl': data['storeIconImageUrl'], // 店舗アイコン画像URLを追加
            };
          }).toList();
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('投稿読み込みエラー: $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }
  
  // クーポンデータの読み込み
  Future<void> _loadCoupons() async {
    try {
      print('クーポン読み込み開始');
      
      // インデックスエラーを避けるため、シンプルなクエリを使用
      final couponsSnapshot = await _firestore
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .limit(50)
          .get();

      print('取得したクーポン数: ${couponsSnapshot.docs.length}');
      
      if (mounted) {
        setState(() {
          _coupons = couponsSnapshot.docs.map((doc) {
            final data = doc.data();
            final endDate = data['endDate'];
            final now = DateTime.now();
            
            // クライアントサイドで使用可能期間と使用済みをチェック
            bool isAvailable = false;
            DateTime? startDateTime;
            DateTime? endDateTime;
            
            try {
              // 開始日をチェック
              if (data['startDate'] != null) {
                startDateTime = (data['startDate'] as Timestamp).toDate();
              }
              
              // 終了日をチェック
              if (endDate != null) {
                endDateTime = (endDate as Timestamp).toDate();
              }
              
              // 今日の日付（時刻を除く）
              final today = DateTime(now.year, now.month, now.day);
              
              // 開始日以降で終了日未満かチェック
              if (startDateTime != null && endDateTime != null) {
                final startDateOnly = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
                final endDateOnly = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
                isAvailable = today.isAfter(startDateOnly.subtract(const Duration(days: 1))) && 
                             today.isBefore(endDateOnly.add(const Duration(days: 1)));
              } else if (startDateTime != null) {
                // 開始日のみ設定されている場合
                final startDateOnly = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
                isAvailable = today.isAfter(startDateOnly.subtract(const Duration(days: 1)));
              } else if (endDateTime != null) {
                // 終了日のみ設定されている場合
                final endDateOnly = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
                isAvailable = today.isBefore(endDateOnly.add(const Duration(days: 1)));
              } else {
                // 日付が設定されていない場合は使用可能とする
                isAvailable = true;
              }
              
              // 使用済みかチェック（ログインユーザーの場合のみ）
              if (isAvailable && _auth.currentUser != null) {
                final usedUserIds = List<String>.from(data['usedUserIds'] ?? []);
                if (usedUserIds.contains(_auth.currentUser!.uid)) {
                  isAvailable = false;
                }
              }
            } catch (e) {
              print('日付変換エラー: $e');
              isAvailable = false;
            }
            
            return {
              'couponId': doc.id,
              'title': data['title'] ?? 'タイトルなし',
              'description': data['description'] ?? '',
              'discountType': data['discountType'] ?? '割引率',
              'discountValue': data['discountValue'] ?? '',
              'startDate': data['startDate'],
              'endDate': data['endDate'],
              'startDateTime': startDateTime, // ソート用のDateTime
              'endDateTime': endDateTime, // ソート用のDateTime
              'imageUrl': data['imageUrl'],
              'storeName': data['storeName'] ?? '店舗名なし',
              'conditions': data['conditions'] ?? '',
              'isAvailable': isAvailable,
            };
          })
          .where((coupon) => coupon['isAvailable'] == true) // 使用可能なクーポンのみ
          .toList()
          ..sort((a, b) {
            // 期限が近い順にソート
            final aEndDate = a['endDateTime'] as DateTime?;
            final bEndDate = b['endDateTime'] as DateTime?;
            
            if (aEndDate == null && bEndDate == null) return 0;
            if (aEndDate == null) return 1;
            if (bEndDate == null) return -1;
            
            return aEndDate.compareTo(bEndDate);
          });
          _isLoadingCoupons = false;
        });
      }
    } catch (e) {
      print('クーポン読み込みエラー: $e');
      if (mounted) {
        setState(() {
          _isLoadingCoupons = false;
        });
      }
    }
  }
  
  // 未読通知の確認
  Future<void> _checkUnreadNotifications(String userId) async {
    try {
      // 全ての通知を取得
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('isActive', isEqualTo: true)
          .where('isPublished', isEqualTo: true)
          .get();
      
      // ユーザーの既読リストを取得
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final readNotifications = userDoc.exists 
          ? List<String>.from(userDoc.data()!['readNotifications'] ?? [])
          : <String>[];
      
      // 未読通知があるかチェック
      bool hasUnread = false;
      for (final doc in notificationsSnapshot.docs) {
        if (!readNotifications.contains(doc.id)) {
          hasUnread = true;
          break;
        }
      }
      
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = hasUnread;
        });
      }
    } catch (e) {
      print('未読通知の確認エラー: $e');
    }
  }
  
  // スロットの利用可能性をチェック（キャッシュされたデータを使用）
  Future<void> _checkSlotAvailability() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('ユーザー未ログイン、スロット非表示');
        if (mounted) {
          setState(() {
            _isSlotAvailable = false;
          });
        }
        return;
      }
      
      print('スロット可用性チェック開始、キャッシュされた履歴: ${_slotHistory.length}件');
      
      // キャッシュされたスロット履歴を使用
      final todayPlayCount = _slotHistory.length;
      final isAvailable = todayPlayCount < 1;
      
      print('今日のプレイ回数: $todayPlayCount, 利用可能: $isAvailable');
      
      if (mounted) {
        setState(() {
          _isSlotAvailable = isAvailable;
        });
      }
      
      print('スロット可用性チェック完了: $_isSlotAvailable');
    } catch (e) {
      print('スロット可用性チェックエラー: $e');
      // エラーの場合は安全のため非表示にする
      if (mounted) {
        setState(() {
          _isSlotAvailable = false;
        });
      }
    }
  }
  
  // ユーザーデータの監視
  void _listenToUserData() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // ユーザーがログインしている場合
        if (mounted) {
          setState(() {
            isLogin = true;
          });
        }
        
        // Firestoreからユーザー情報を取得
        _firestore.collection('users').doc(user.uid).snapshots().listen((snapshot) async {
          if (snapshot.exists && mounted) {
            final data = snapshot.data()!;
            
            // ユーザーデータからゴールドスタンプ数を直接取得
            final userGoldStamps = data['goldStamps'] ?? 0;
            
            if (mounted) {
              setState(() {
                points = data['points'] ?? 0;
                goldStamps = userGoldStamps;
                paid = data['paid'] ?? 10000;
              });
            }
            
            // データベースのランクと現在計算されたランクが異なる場合は更新
            final dbRank = data['rank'] ?? 'ブロンズ';
            final calculatedRank = _getCurrentRankName();
            if (dbRank != calculatedRank) {
              _updateRank();
            }
          }
        });
      } else {
        // ユーザーがログインしていない場合
        if (mounted) {
          setState(() {
            isLogin = false;
            points = 0;
            goldStamps = 0;
            paid = 10000;
          });
        }
      }
    });
  }

  // ランク計算メソッド
  int _calculateRank() {
    // 新しいランクシステム：ゴールドスタンプ数 + 総利用金額
    if (goldStamps >= 15 && paid >= 50000) return 4; // プラチナ
    if (goldStamps >= 7 && paid >= 20000) return 3;  // ゴールド
    if (goldStamps >= 3 && paid >= 5000) return 2;   // シルバー
    return 1; // ブロンズ
  }

  // 現在のランク名を取得
  String _getCurrentRankName() {
    final currentRank = _calculateRank();
    switch (currentRank) {
      case 1: return 'ブロンズ';
      case 2: return 'シルバー';
      case 3: return 'ゴールドスタンプ';
      case 4: return 'プラチナ';
      default: return 'ブロンズ';
    }
  }

  // 次のランクまでの条件を取得
  Map<String, dynamic> _getNextRankRequirements() {
    final currentRank = _calculateRank();
    switch (currentRank) {
      case 1: // ブロンズ → シルバー
        return {
          'rank': 'シルバー',
          'goldStamps': 3,
          'paid': 5000,
          'color': Colors.grey,
        };
      case 2: // シルバー → ゴールド
        return {
          'rank': 'ゴールドスタンプ',
          'goldStamps': 7,
          'paid': 20000,
          'color': Colors.amber,
        };
      case 3: // ゴールド → プラチナ
        return {
          'rank': 'プラチナ',
          'goldStamps': 15,
          'paid': 50000,
          'color': Colors.blue,
        };
      default: // プラチナ（最高ランク）
        return {
          'rank': 'プラチナ',
          'goldStamps': 15,
          'paid': 50000,
          'color': Colors.blue,
        };
    }
  }

  // ユーザーデータの確実な読み込み
  Future<void> _loadUserData(String userId) async {
    try {
      print('ユーザーデータ読み込み開始: $userId');
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('ユーザードキュメントが存在しません: $userId');
        return;
      }
      
      final data = userDoc.data()!;
      print('ユーザーデータ: $data');
      
      if (mounted) {
        setState(() {
          points = data['points'] ?? 0;
          goldStamps = data['goldStamps'] ?? 0;
          paid = data['paid'] ?? 10000;
          isLogin = true;
        });
      }
      
      // チュートリアル表示チェック
      final showTutorial = data['showTutorial'] ?? false;
      if (showTutorial) {
        _showTutorial();
      }
      
      print('ユーザーデータ読み込み完了: points=$points, goldStamps=$goldStamps, paid=$paid');
    } catch (e) {
      print('ユーザーデータ読み込みエラー: $e');
    }
  }
  
  // スロット履歴の読み込み
  Future<void> _loadSlotHistory(String userId) async {
    try {
      print('スロット履歴読み込み開始: $userId');
      
      // 今日の日付を取得
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // まずシンプルなクエリでユーザーのスロット履歴を取得
      final slotHistorySnapshot = await _firestore
          .collection('slot_history')
          .where('userId', isEqualTo: userId)
          .get();
      
      print('取得したスロット履歴総数: ${slotHistorySnapshot.docs.length}');
      
      // 今日のデータをクライアントサイドでフィルタリング
      final todaySlotHistory = slotHistorySnapshot.docs.where((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp == null) return false;
        
        final docDate = timestamp.toDate();
        final docDay = DateTime(docDate.year, docDate.month, docDate.day);
        return docDay.isAtSameMomentAs(today);
      }).map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      print('今日のスロット履歴: ${todaySlotHistory.length}件');
      
      if (mounted) {
        setState(() {
          _slotHistory = todaySlotHistory;
        });
      }
      
      print('スロット履歴読み込み完了');
    } catch (e) {
      print('スロット履歴読み込みエラー: $e');
      if (mounted) {
        setState(() {
          _slotHistory = [];
        });
      }
    }
  }

  // ユーザーデータの手動更新（後方互換性のため残す）
  Future<void> _refreshUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    }
  }

  // チュートリアルを表示
  Future<void> _showTutorial() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // チュートリアル表示フラグをfalseに更新
        await _firestore.collection('users').doc(user.uid).update({
          'showTutorial': false,
        });
        
        // チュートリアル画面に遷移
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const TutorialView(),
            ),
          );
        }
      } catch (e) {
        print('チュートリアル表示処理エラー: $e');
      }
    }
  }

  // 既存ユーザーにisOwnerフィールドを追加
  Future<void> _addOwnerFieldToExistingUsers() async {
    try {
      print('既存ユーザーへのオーナーステータス追加処理を開始...');
      
      final usersSnapshot = await _firestore.collection('users').get();
      final batch = _firestore.batch();
      
      int updateCount = 0;
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('isOwner')) {
          batch.update(doc.reference, {'isOwner': false});
          updateCount++;
        }
      }
      
      if (updateCount > 0) {
        await batch.commit();
        print('$updateCount 人のユーザーにオーナーステータスを追加しました');
      } else {
        print('既存ユーザーは既にオーナーステータスを持っています');
      }
    } catch (e) {
      print('既存ユーザーへのオーナーステータス追加に失敗しました: $e');
      print('既存ユーザーへのオーナーステータス追加処理でエラーが発生しました: Exception: 既存ユーザーへのオーナーステータス追加に失敗しました:\n$e');
    }
  }

  // 探索スタンプ数を更新
  Future<void> _updateGoldStamps(int newGoldStamps) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'goldStamps': newGoldStamps,
        });
        
        // ローカル状態も更新
        setState(() {
          goldStamps = newGoldStamps;
        });
        
        // ランクも更新
        await _updateRank();
        
        print('ゴールドスタンプ数更新完了: $newGoldStamps');
      } catch (e) {
        print('探索スタンプ数更新エラー: $e');
      }
    }
  }



  // ポイント数を更新
  Future<void> _updatePoints(int newPoints) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'points': newPoints,
        });
        
        // ローカル状態も更新
        setState(() {
          points = newPoints;
        });
        
        print('ポイント数更新完了: $newPoints');
      } catch (e) {
        print('ポイント数更新エラー: $e');
      }
    }
  }

  // 総支払額を更新
  Future<void> _updatePaid(int newPaid) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'paid': newPaid,
        });
        
        // ローカル状態も更新
        setState(() {
          paid = newPaid;
        });
        
        // ランクも更新
        await _updateRank();
        
        print('総支払額更新完了: $newPaid');
      } catch (e) {
        print('総支払額更新エラー: $e');
      }
    }
  }

  // ランクを更新
  Future<void> _updateRank() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final newRank = _getCurrentRankName();
        await _firestore.collection('users').doc(user.uid).update({
          'rank': newRank,
        });
        
        print('ランク更新完了: $newRank');
      } catch (e) {
        print('ランク更新エラー: $e');
      }
    }
  }

  // ランクに応じた還元率を取得
  double _getRankReturnRate() {
    final currentRank = _calculateRank();
    switch (currentRank) {
      case 1: return 0.5;  // ブロンズ
      case 2: return 1.0;  // シルバー
      case 3: return 1.5;  // ゴールドスタンプ
      case 4: return 2.0;  // プラチナ
      default: return 0.5; // ブロンズ
    }
  }

  // ランクに応じた色を取得
  Color _getRankColor() {
    final currentRank = _calculateRank();
    switch (currentRank) {
      case 1: return const Color(0xFFFF6B35); // ブロンズ（オレンジ）
      case 2: return Colors.grey; // シルバー（グレー）
      case 3: return Colors.amber; // ゴールドスタンプ（アンバー）
      case 4: return Colors.blue; // プラチナ（ブルー）
      default: return const Color(0xFFFF6B35); // ブロンズ（オレンジ）
    }
  }

  // ランクに応じたトロフィーアイコンを取得
  String _getRankTrophyIcon() {
    final currentRank = _calculateRank();
    switch (currentRank) {
      case 1: return 'assets/images/bronz_trophy_icon.png'; // ブロンズ
      case 2: return 'assets/images/silver_trophy_icon.png'; // シルバー
      case 3: return 'assets/images/gold_trophy_icon.png'; // ゴールド
      case 4: return 'assets/images/platinum_trophy_icon.png'; // プラチナ
      default: return 'assets/images/bronz_trophy_icon.png'; // ブロンズ
    }
  }

  // 次のランクに応じたトロフィーアイコンを取得
  String _getNextRankTrophyIcon() {
    final nextRank = _getNextRankRequirements();
    switch (nextRank['rank']) {
      case 'シルバー': return 'assets/images/silver_trophy_icon.png';
      case 'ゴールドスタンプ': return 'assets/images/gold_trophy_icon.png';
      case 'プラチナ': return 'assets/images/platinum_trophy_icon.png';
      default: return 'assets/images/platinum_trophy_icon.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // backWhite
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildTitleView(),
            _buildCardView(),
            const SizedBox(height: 10),
            _buildPointView(),
            const SizedBox(height: 10),
            // テスト用フラワー操作ボタン（開発時のみ）
            if (isLogin) _buildTestGoldStampsControls(),
            const SizedBox(height: 10),
            _buildRouletteView(),
            const SizedBox(height: 10),
            _buildMenuView(),
            const SizedBox(height: 10),
            _buildRankView(),
            const SizedBox(height: 20),
            // _buildSlideView(),
            // const SizedBox(height: 20),
            _buildCouponView(),
            const SizedBox(height: 20),
            _buildPostView(),
            const SizedBox(height: 200), // 最下部の余白を増加
          ],
        ),
      ),
    );
  }

  // MARK: - titleView
  Widget _buildTitleView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 左側の空白
          const SizedBox(width: 20),
          const Spacer(),
          // 中央のタイトル（ロゴ）
          const Text(
            'GourMap',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35), // オレンジ系の温かみのある色
            ),
          ),
          const Spacer(),
          // 右側の通知ボタン
          GestureDetector(
            onTap: () async {
              // 通知画面に遷移
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationListView(),
                ),
              );
              
              // 通知画面から戻ってきた時に未読状態を更新
              final user = _auth.currentUser;
              if (user != null) {
                _checkUnreadNotifications(user.uid);
              }
            },
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(
                    Icons.notifications,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
                // 未読通知の赤い丸（未読通知がある場合のみ表示）
                if (_hasUnreadNotifications)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - cardView
  Widget _buildCardView() {
    final user = _auth.currentUser;
    final uid = user?.uid ?? '';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: 270,
      height: 190,
      decoration: BoxDecoration(
        color: _getRankColor().withOpacity(0.1), // ランクに応じた背景色
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getRankColor().withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getRankColor().withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // ランクを一番上に表示
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getCurrentRankName(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getRankColor(),
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                _getRankTrophyIcon(),
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.emoji_events,
                    color: _getRankColor(),
                    size: 24,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '還元率：${_getRankReturnRate()}%',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          // QRコード部分
          Container(
            width: 250,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // QRコード（自身のuidで生成）
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: uid.isNotEmpty
                      ? QrImageView(
                          data: uid,
                          version: QrVersions.auto,
                          size: 40,
                          backgroundColor: Colors.white,
                        )
                      : const Icon(
                          Icons.qr_code,
                          size: 30,
                          color: Colors.grey,
                        ),
                ),
                const SizedBox(width: 15),
                // 右側の情報
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QRコード',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ユーザー識別用',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 輝度変更ボタン
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (isBright) {
                                SystemChrome.setSystemUIOverlayStyle(
                                  const SystemUiOverlayStyle(
                                    statusBarBrightness: Brightness.light,
                                  ),
                                );
                                isBright = false;
                              } else {
                                SystemChrome.setSystemUIOverlayStyle(
                                  const SystemUiOverlayStyle(
                                    statusBarBrightness: Brightness.dark,
                                  ),
                                );
                                isBright = true;
                              }
                            });
                          },
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFF666666),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isBright ? Icons.wb_sunny : Icons.wb_sunny_outlined,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }



  // MARK: - pointView
  Widget _buildPointView() {
    if (!isLogin) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'ログインしてポイントを確認',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ポイント
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    ClipOval(
                      child: Image.asset(
                        'assets/images/point_icon.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 画像が読み込めない場合のフォールバック
                          return Icon(
                            Icons.monetization_on,
                            color: const Color(0xFFFF6B35),
                            size: 20,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$points',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'pt',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        _refreshUserData();
                      },
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: const BoxDecoration(
                          color: Color(0xFF666666),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // ゴールドスタンプ
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    ClipOval(
                      child: Image.asset(
                        'assets/images/gold_coin_icon2.png',
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
                    Text(
                      '$goldStamps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'ゴールドスタンプ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        _refreshUserData();
                      },
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: const BoxDecoration(
                          color: Color(0xFF666666),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - rouletteView
  Widget _buildRouletteView() {
    // ログインしていない場合、またはスロットが利用不可能な場合は非表示
    if (!isLogin || !_isSlotAvailable) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: () {
        if (!isLogin) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LoginView(),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SlotMachineView(),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.width / 6,
        decoration: BoxDecoration(
          gradient: isLogin 
            ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // ゴールドグラデーション
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Colors.grey, Colors.grey],
              ),
          boxShadow: isLogin 
            ? [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
        ),
        child: Stack(
          children: [
            // 背景装飾
            if (isLogin) ...[
              Positioned(
                left: 20,
                top: 10,
                child: Icon(
                  Icons.star,
                  color: Colors.yellow[200],
                  size: 20,
                ),
              ),
              Positioned(
                right: 20,
                bottom: 10,
                child: Icon(
                  Icons.star,
                  color: Colors.yellow[200],
                  size: 16,
                ),
              ),
              Positioned(
                left: 50,
                bottom: 15,
                child: Icon(
                  Icons.casino,
                  color: Colors.white.withOpacity(0.3),
                  size: 24,
                ),
              ),
            ],
            // メインコンテンツ
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLogin) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.casino,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    isLogin ? 'スロットチャレンジ' : 'ログインしてスロット',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isLogin ? Colors.white : Colors.white,
                      shadows: isLogin 
                        ? [
                            Shadow(
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ]
                        : null,
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

  // MARK: - menuView
  Widget _buildMenuView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: 320,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMenuButton('ポイント', 'assets/images/point_icon.png', isLogin, isImage: true),
            _buildMenuButton('スタンプ', 'assets/images/gold_coin_icon2.png', isLogin, isImage: true),
            _buildMenuButton('友達紹介', 'assets/images/friend_intro_icon.png', isLogin, isImage: true),
            _buildMenuButton('店舗一覧', 'assets/images/store_icon.png', isLogin, isImage: true),
            _buildMenuButton('ランキング', 'assets/images/trophy_icon.png', isLogin, isImage: true),
            _buildMenuButton('フィードバック', 'assets/images/chats_icon.png', isLogin, isImage: true),
            _buildMenuButton('店舗導入', 'assets/images/smartphone_qrcode_icon.png', isLogin, isImage: true),
          ],
        ),
      ),
    );
  }

  // MARK: - rankView
  Widget _buildRankView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: 320,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー部分
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        _getRankTrophyIcon(),
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 16,
                          );
                        },
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _getCurrentRankName(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RankDetailView(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ランクについて',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 次のランク情報
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '次のランクまで',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              _getNextRankRequirements()['rank'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getNextRankRequirements()['color'],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Image.asset(
                              _getNextRankTrophyIcon(),
                              width: 14,
                              height: 14,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.emoji_events,
                                  color: _getNextRankRequirements()['color'],
                                  size: 14,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // プログレスバー
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRankBar('ゴールドスタンプ', goldStamps, _getNextRankRequirements()['goldStamps'], Icons.star, '個', Colors.amber),
                const SizedBox(height: 12),
                _buildRankBar('総支払い額', paid, _getNextRankRequirements()['paid'], Icons.attach_money, '円', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - slideView
  Widget _buildSlideView() {
    return SizedBox(
      width: 320,
      height: 90,
      child: PageView.builder(
        itemCount: pages.length,
        onPageChanged: (index) {
          if (mounted) {
            setState(() {
              selectedSlide = index + 1;
            });
          }
        },
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'スライド ${pages[index]}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // MARK: - couponView
  Widget _buildCouponView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              const Text(
                'クーポン',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  widget.onTabChanged(4);
                  widget.onCouponViewChanged(true);
                },
                child: const Text(
                  '全て見る＞',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: _isLoadingCoupons
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF6B35),
                  ),
                )
              : _coupons.isEmpty
                  ? const Center(
                      child: Text(
                        '利用可能なクーポンがありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _coupons.length,
                      itemBuilder: (context, index) {
                        final coupon = _coupons[index];
                        return _buildCouponCard(coupon);
                      },
                    ),
        ),
      ],
    );
  }

  // MARK: - postView
  Widget _buildPostView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              const Text(
                '店舗からのお知らせ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  widget.onTabChanged(4);
                  widget.onCouponViewChanged(false);
                },
                child: const Text(
                  '全て見る＞',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 350,
          child: _isLoadingPosts
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF6B35),
                  ),
                )
              : _posts.isEmpty
                  ? const Center(
                      child: Text(
                        '投稿がありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return _buildPostCard(post);
                      },
                    ),
        ),
      ],
    );
  }

  // クーポンカードを作成
  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    // 終了日の表示用フォーマット
    String formatEndDate() {
      final endDate = coupon['endDate'];
      if (endDate == null) return '期限不明';
      
      try {
        final date = (endDate as Timestamp).toDate();
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

    // 割引表示用テキスト
    String getDiscountText() {
      final discountType = coupon['discountType'] ?? '割引率';
      final discountValue = coupon['discountValue'] ?? '';
      
      if (discountType == '割引率') {
        return '$discountValue%OFF';
      } else if (discountType == '割引額') {
        return '${discountValue}円OFF';
      } else if (discountType == '固定価格') {
        return '${discountValue}円';
      }
      return '特典あり';
    }

    return GestureDetector(
      onTap: () {
        final couponId = coupon['couponId'];
        if (couponId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CouponDetailView(couponId: couponId),
            ),
          );
        }
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 5),
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
          children: [
            // 画像
            Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.only(top: 7, bottom: 7),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
              child: coupon['imageUrl'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        coupon['imageUrl'],
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFFFF6B35),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
            ),
            
            // 期限
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                formatEndDate(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 6),
            
            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                coupon['title'] ?? 'タイトルなし',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // 割引情報
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                getDiscountText(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const Divider(height: 1),
            
            // 店舗名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                coupon['storeName'] ?? '店舗名なし',
                style: const TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 3),
          ],
        ),
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
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(
            Icons.image,
            size: 50,
            color: Colors.grey,
          ),
        );
      }
      
      // 新しい形式のimageUrlsをチェック
      final imageUrls = post['imageUrls'] as List?;
      if (imageUrls != null && imageUrls.isNotEmpty) {
        final imageUrl = imageUrls[0] as String;
        print('画像URL: $imageUrl');
        
        // Base64データかどうかをチェック
        if (imageUrl.startsWith('data:image/')) {
          try {
            final base64String = imageUrl.split(',')[1];
            final imageBytes = base64Decode(base64String);
            return ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.memory(
                imageBytes,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            );
          } catch (e) {
            print('Base64デコードエラー: $e');
            return buildErrorImage();
          }
        } else {
          // Firebase Storage URLの場合
          print('Firebase Storage URL検出: $imageUrl');
          
          // CORS問題を回避するため、画像を直接表示
          return ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.network(
              imageUrl,
              width: 150,
              height: 150,
              fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFFFF6B35),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '読み込み中...',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('画像読み込みエラー: $imageUrl, エラー: $error');
                
                // エラー時の表示を改善
                return GestureDetector(
                  onTap: () async {
                    // タップすると新しいタブでFirebase Storage URLを開く
                    try {
                      final uri = Uri.parse(imageUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                        print('Firebase Storage URLをブラウザで開きました: $imageUrl');
                      } else {
                        print('URLを開けませんでした: $imageUrl');
                        // フォールバック: クリップボードにコピー
                        await Clipboard.setData(ClipboardData(text: imageUrl));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('画像URLをクリップボードにコピーしました'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('URL起動エラー: $e');
                      // フォールバック: クリップボードにコピー
                      await Clipboard.setData(ClipboardData(text: imageUrl));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('画像URLをクリップボードにコピーしました'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.orange[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '画像読み込みエラー\nタップで詳細確認',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new,
                                size: 8,
                                color: Colors.blue[800],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'タップで表示',
                                style: TextStyle(
                                  fontSize: 7,
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(${post['imageCount'] ?? 0}枚)',
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
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
            borderRadius: BorderRadius.circular(7),
            child: Image.memory(
              imageBytes,
              width: 150,
              height: 150,
              fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
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
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 5),
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
          children: [
            // 画像
            Container(
              margin: const EdgeInsets.only(top: 7, bottom: 7),
              child: buildImage(),
            ),
            
            // カテゴリバッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                post['category'] ?? 'お知らせ',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFFF6B35),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                post['title'] ?? 'タイトルなし',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 5),
            
            // 内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  post['content'] ?? '',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                  ),
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            const Divider(),
            
            // 店舗アイコンと店舗名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 店舗アイコン
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: post['storeIconImageUrl'] != null
                          ? Image.network(
                              post['storeIconImageUrl'],
                              width: 16,
                              height: 16,
                              fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.store,
                                  color: Colors.grey,
                                  size: 10,
                                );
                              },
                            )
                          : const Icon(
                              Icons.store,
                              color: Colors.grey,
                              size: 10,
                            ),
                    ),
                  ),
                  // 店舗名
                  Expanded(
                    child: Text(
                      post['storeName'] ?? '店舗名なし',
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 5),
            
            // 投稿日
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatDate(),
                  style: const TextStyle(
                    fontSize: 7,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  // ヘルパーメソッド
  Widget _buildCustomCapsule({
    required String text,
    required Color foregroundColor,
    required Color textColor,
    required bool isStroke,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isStroke ? Colors.transparent : foregroundColor,
          border: isStroke ? Border.all(color: Colors.black) : null,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(String title, dynamic icon, bool isLogin, {bool isImage = false}) {
    return GestureDetector(
      onTap: () {
        if (!isLogin) {
          // ログインしていない場合はログイン画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LoginView(),
            ),
          );
          return;
        }

        if (title == 'ポイント') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PointHistoryView(),
            ),
          );
        } else if (title == 'スタンプ') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const StampView(),
            ),
          );
        } else if (title == '友達紹介') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FriendIntroView(),
            ),
          );
        } else if (title == '店舗一覧') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const StoreListView(),
            ),
          );
        } else if (title == 'ランキング') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RankingListView(),
            ),
          );
        } else if (title == 'フィードバック') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FeedbackView(),
            ),
          );
        } else if (title == '店舗導入') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const QRCodeView(),
            ),
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isImage
              ? Image.asset(
                  icon,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('画像読み込みエラー: $error');
                    return Icon(
                      Icons.monetization_on,
                      size: 24,
                      color: isLogin ? const Color(0xFFFF6B35) : Colors.grey,
                    );
                  },
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  },
                )
              : Icon(
                  icon,
                  size: 24,
                  color: isLogin ? const Color(0xFFFF6B35) : Colors.grey,
                ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isLogin ? Colors.black : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // テスト用スタンプ操作ボタン（開発時のみ）
  Widget _buildTestGoldStampsControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'テスト用スタンプ操作',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _updatePaid(paid + 1000),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('支払額+1000'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (paid > 0) {
                    _updatePaid(paid - 1000);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: paid > 0 ? Colors.red : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('支払額-1000'),
              ),
              ElevatedButton(
                onPressed: () => _updatePaid(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('支払額リセット'),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildRankBar(String title, int value, int maxValue, IconData icon, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '$value$unit / $maxValue$unit',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value / maxValue,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
} 