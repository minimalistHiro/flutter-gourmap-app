import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/referral_service.dart';

class FriendIntroView extends StatefulWidget {
  const FriendIntroView({super.key});

  @override
  State<FriendIntroView> createState() => _FriendIntroViewState();
}

class _FriendIntroViewState extends State<FriendIntroView> {
  bool isShowCopyMessage = false;
  String friendIntroCode = "";
  bool _isLoading = true;
  String _username = "";
  Map<String, int> _referralStats = {'referralCount': 0, 'totalPointsEarned': 0};
  List<Map<String, dynamic>> _referralHistory = [];
  
  final ReferralService _referralService = ReferralService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  // 紹介データを読み込み
  Future<void> _loadReferralData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // ユーザー名を取得
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _username = userData['username'] ?? 'ユーザー';
      }

      // 紹介コードを取得
      final referralCode = await _referralService.getUserReferralCode(user.uid);
      
      // 紹介統計を取得
      final stats = await _referralService.getReferralStats(user.uid);
      
      // 紹介履歴を取得
      final history = await _referralService.getReferralHistory(user.uid);

      if (mounted) {
        setState(() {
          friendIntroCode = referralCode;
          _referralStats = stats;
          _referralHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('紹介データ読み込みエラー: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データの読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // backWhite
      appBar: AppBar(
        title: const Text(
          '友達紹介',
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
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 統計カード
                      _buildStatsCard(),
                      
                      const SizedBox(height: 20),
                      
                      // タイトルテキスト
                      const Text(
                        '友達を紹介すると、双方に',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      const Text(
                        '1000ポイントもらえる！',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // 紹介コードタイトル
                      Text(
                        '${_username}さんの紹介コード',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // 紹介コードカード
                      Container(
                        width: 320,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFFF6B35),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            Text(
                              friendIntroCode,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF6B35),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 20),
                            // コピーボタン
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: friendIntroCode));
                                setState(() {
                                  isShowCopyMessage = true;
                                });
                                // 2秒後にメッセージを非表示
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted) {
                                    setState(() {
                                      isShowCopyMessage = false;
                                    });
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.copy,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 友達にシェアボタン
                      _buildCustomCapsule(
                        text: '友達にシェア',
                        foregroundColor: const Color(0xFFFF6B35),
                        textColor: Colors.white,
                        isStroke: false,
                        onTap: () {
                          _shareReferralCode();
                        },
                      ),
                
                const SizedBox(height: 60),
                
                // 友達紹介方法タイトル
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 30),
                    child: Text(
                      '友達紹介方法',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // ステップ1
                _buildStepView(
                  step: 1,
                  title: '紹介コードを友達にシェアする',
                  text: '上記「友達にシェア」より、友達にSNS等で紹介コードを教えましょう。',
                  imageName: 'SmartPhoneHand',
                ),
                
                // ステップ2
                _buildStepView(
                  step: 2,
                  title: '友達に紹介コードを登録してもらう',
                  text: '友達が新規アカウント作成時、紹介コード入力欄に紹介コードを入力してもらいましょう。',
                  imageName: 'SmartPhoneMen',
                ),
                
                // ステップ3
                _buildStepView(
                  step: 3,
                  title: '紹介者、友達の双方に1000pt付与',
                  text: '友達が新規登録を完了すると、自動的に双方に1000ポイントが付与されます。',
                  imageName: 'Flower',
                ),
                
                // 紹介履歴
                if (_referralHistory.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _buildReferralHistory(),
                ],
                
                const SizedBox(height: 50),
              ],
            ),
          ),
          
          // コピーメッセージ
          if (isShowCopyMessage)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'コピーしました',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // シェア機能
  void _shareReferralCode() {
    final message = '''
GourMapに招待します！

紹介コード: $friendIntroCode

新規登録時にこのコードを入力すると、
お互いに1000ポイントがもらえます🎉

アプリをダウンロードして、一緒にポイントを貯めましょう！
''';

    Share.share(message, subject: 'GourMap 友達紹介');
  }

  // 統計カード
  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '紹介実績',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatItemWithImage(
                  '紹介した友達',
                  '${_referralStats['referralCount']}人',
                  'assets/images/friend_intro_icon.png',
                  Colors.blue,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildStatItemWithImage(
                  '獲得ポイント',
                  '${_referralStats['totalPointsEarned']}pt',
                  'assets/images/point_icon.png',
                  const Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 統計アイテム
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // 統計アイテム（画像版）
  Widget _buildStatItemWithImage(String label, String value, String imagePath, Color color) {
    return Column(
      children: [
        Image.asset(
          imagePath,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 画像が読み込めない場合のフォールバック
            return Icon(
              label == '紹介した友達' ? Icons.people : Icons.monetization_on,
              color: color,
              size: 24,
            );
          },
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // 紹介履歴
  Widget _buildReferralHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '紹介履歴',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 15),
          ..._referralHistory.take(5).map((history) => _buildHistoryItem(history)),
          if (_referralHistory.length > 5)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                '... その他の履歴があります',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 履歴アイテム
  Widget _buildHistoryItem(Map<String, dynamic> history) {
    String formatDate() {
      final createdAt = history['createdAt'];
      if (createdAt == null) return '日付不明';
      
      try {
        final date = (createdAt as Timestamp).toDate();
        return '${date.year}/${date.month}/${date.day}';
      } catch (e) {
        return '日付不明';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B35),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${history['newUserName']}さんが参加',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${history['pointsAwarded']}pt獲得 • ${formatDate()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
        ],
      ),
    );
  }

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
        width: 200,
        height: 50,
        decoration: BoxDecoration(
          color: isStroke ? Colors.transparent : foregroundColor,
          borderRadius: BorderRadius.circular(25),
          border: isStroke ? Border.all(color: foregroundColor, width: 2) : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepView({
    required int step,
    required String title,
    required String text,
    required String imageName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          // STEPラベル
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Container(
                width: 80,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    'STEP$step',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 7),
          
          // ステップ内容
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                // テキスト部分
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (text.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 5),
                
                // 画像部分
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconForImageName(imageName),
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForImageName(String imageName) {
    switch (imageName) {
      case 'SmartPhoneHand':
        return Icons.phone_android;
      case 'SmartPhoneMen':
        return Icons.person;
      case 'SmartPhoneQRCode':
        return Icons.qr_code;
      case 'Flower':
        return Icons.local_florist;
      default:
        return Icons.image;
    }
  }
} 