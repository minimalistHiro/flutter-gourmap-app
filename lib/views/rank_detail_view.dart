import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RankDetailView extends StatefulWidget {
  const RankDetailView({super.key});

  @override
  State<RankDetailView> createState() => _RankDetailViewState();
}

class _RankDetailViewState extends State<RankDetailView> {
  // 現在のユーザーデータ
  int currentGoldStamps = 0;
  int currentPaid = 0;
  String currentRank = 'ブロンズ';
  bool _isLoading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ユーザーデータを読み込む
  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          
          setState(() {
            currentGoldStamps = userData['goldStamps'] ?? 0;
            currentPaid = userData['totalPaid'] ?? 0;
            currentRank = _calculateCurrentRank(currentGoldStamps, currentPaid);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('ユーザーデータ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 現在のランクを計算
  String _calculateCurrentRank(int goldStamps, int totalPaid) {
    if (goldStamps >= 30 && totalPaid >= 100000) return 'ダイヤモンド';
    if (goldStamps >= 15 && totalPaid >= 50000) return 'プラチナ';
    if (goldStamps >= 7 && totalPaid >= 20000) return 'ゴールド';
    if (goldStamps >= 3 && totalPaid >= 5000) return 'シルバー';
    return 'ブロンズ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'ランク詳細',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // 現在のランクセクション
                  _buildCurrentRankSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 次のランクセクション
                  _buildNextRankSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 全ランクリストセクション
                  _buildAllRanksSection(),
                  
                  const SizedBox(height: 20),
                  
                  // ランクアップ方法セクション
                  _buildRankUpMethodsSection(),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  // 現在のランクセクション
  Widget _buildCurrentRankSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getRankGradient(currentRank),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getRankColor(currentRank).withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '現在のランク',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 現在のランク名
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentRank,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.emoji_events,
                  color: Colors.yellow,
                  size: 30,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 15),
          
          // 現在のパラメータ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildParameterCard(
                'ゴールドスタンプ',
                '$currentGoldStamps',
                '個',
                'assets/images/gold_coin_icon.png',
                Colors.amber,
              ),
              _buildParameterCard(
                '総支払額',
                '${(currentPaid / 1000).toStringAsFixed(1)}',
                '千円',
                Icons.monetization_on,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 次のランクセクション
  Widget _buildNextRankSection() {
    final nextRankInfo = _getNextRankInfo(currentRank);
    final remainingGoldStamps = nextRankInfo['requiredGoldStamps'] - currentGoldStamps;
    final remainingPaid = nextRankInfo['requiredPaid'] - currentPaid;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: _getRankColor(nextRankInfo['rank']),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                '次のランク: ${nextRankInfo['rank']}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getRankColor(nextRankInfo['rank']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 残り必要なパラメータ
          Text(
            'ランクアップまでに必要なもの:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          
          _buildProgressBar(
            'ゴールドスタンプ',
            currentGoldStamps,
            nextRankInfo['requiredGoldStamps'],
            remainingGoldStamps > 0 ? remainingGoldStamps : 0,
            'assets/images/gold_coin_icon.png',
            Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            '総支払額',
            currentPaid,
            nextRankInfo['requiredPaid'],
            remainingPaid > 0 ? remainingPaid : 0,
            Icons.monetization_on,
            Colors.green,
          ),
        ],
      ),
    );
  }

  // 全ランクリストセクション
  Widget _buildAllRanksSection() {
    final allRanks = _getAllRanks();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.list_alt,
                color: Colors.blue[700],
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                '全ランク一覧',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ...allRanks.map((rank) => _buildRankListItem(rank)).toList(),
        ],
      ),
    );
  }

  // ランクアップ方法セクション
  Widget _buildRankUpMethodsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Colors.orange[700],
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'ランクアップ方法',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildMethodStep(
            1,
            '店舗でスタンプを集める',
            'お気に入りの店舗で買い物をして、スタンプカードを完成させましょう。10個のスタンプで1個のゴールドスタンプが獲得できます。',
            Icons.star,
            Colors.amber,
          ),
          
          _buildMethodStep(
            2,
            '定期的に買い物をする',
            '毎月一定額以上の買い物をすることで、総支払額を増やしましょう。',
            Icons.shopping_cart,
            Colors.green,
          ),
          
          _buildMethodStep(
            3,
            '友達を紹介する',
            '友達にアプリを紹介すると、ボーナスポイントや特別な特典がもらえる場合があります。',
            Icons.people,
            Colors.blue,
          ),
          
          _buildMethodStep(
            4,
            'クーポンを活用する',
            '店舗が提供するクーポンを使用して、お得に買い物をしましょう。',
            Icons.local_offer,
            Colors.red,
          ),
          
          _buildMethodStep(
            5,
            'レビューを書く',
            '利用した店舗のレビューを書くことで、ポイントがもらえる場合があります。',
            Icons.rate_review,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  // パラメータカード
  Widget _buildParameterCard(String title, String value, String unit, dynamic icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          icon is String
              ? Image.asset(
                  icon,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 24,
                    );
                  },
                )
              : Icon(icon as IconData, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // プログレスバー
  Widget _buildProgressBar(String title, int current, int required, int remaining, dynamic icon, Color color) {
    final progress = current / required;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon is String
                ? Image.asset(
                    icon,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.monetization_on,
                        color: color,
                        size: 16,
                      );
                    },
                  )
                : Icon(icon as IconData, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              '$current / $required',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress > 1.0 ? 1.0 : progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
        ),
        if (remaining > 0) ...[
          const SizedBox(height: 4),
          Text(
            '残り $remaining 必要',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  // ランクリストアイテム
  Widget _buildRankListItem(Map<String, dynamic> rank) {
    final isCurrentRank = rank['name'] == currentRank;
    final isUnlocked = rank['requiredGoldStamps'] <= currentGoldStamps && 
                       rank['requiredPaid'] <= currentPaid;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isCurrentRank 
            ? _getRankColor(rank['name']).withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isCurrentRank 
              ? _getRankColor(rank['name'])
              : Colors.grey[300]!,
          width: isCurrentRank ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // ランクアイコン
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUnlocked ? _getRankColor(rank['name']) : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events : Icons.lock,
              color: isUnlocked ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          
          const SizedBox(width: 15),
          
          // ランク情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rank['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? _getRankColor(rank['name']) : Colors.grey[600],
                      ),
                    ),
                    if (isCurrentRank) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRankColor(rank['name']),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '現在',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '条件: ゴールドスタンプ${rank['requiredGoldStamps']}個、総支払額${rank['requiredPaid']}円',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ポイント還元率: ${rank['returnRate']}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getRankColor(rank['name']),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
                     // 王冠アイコン
           if (isUnlocked)
             Icon(
               Icons.emoji_events,
               color: _getRankColor(rank['name']),
               size: 24,
             ),
        ],
      ),
    );
  }

  // 方法ステップ
  Widget _buildMethodStep(int step, String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ステップ番号
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 15),
          
          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ランクの色を取得
  Color _getRankColor(String rankName) {
    switch (rankName) {
      case 'ブロンズ':
        return const Color(0xFFCD7F32);
      case 'シルバー':
        return Colors.grey;
      case 'ゴールド':
        return const Color(0xFFFFD700);
      case 'プラチナ':
        return const Color(0xFFE5E4E2);
      case 'ダイヤモンド':
        return const Color(0xFFB9F2FF);
      default:
        return Colors.blue;
    }
  }

  // ランクのグラデーションを取得
  List<Color> _getRankGradient(String rankName) {
    final baseColor = _getRankColor(rankName);
    return [
      baseColor,
      baseColor.withOpacity(0.8),
    ];
  }

  // 次のランク情報を取得
  Map<String, dynamic> _getNextRankInfo(String currentRank) {
    switch (currentRank) {
      case 'ブロンズ':
        return {
          'rank': 'シルバー',
          'requiredGoldStamps': 3,
          'requiredPaid': 5000,
        };
      case 'シルバー':
        return {
          'rank': 'ゴールド',
          'requiredGoldStamps': 7,
          'requiredPaid': 20000,
        };
      case 'ゴールド':
        return {
          'rank': 'プラチナ',
          'requiredGoldStamps': 15,
          'requiredPaid': 50000,
        };
      case 'プラチナ':
        return {
          'rank': 'ダイヤモンド',
          'requiredGoldStamps': 30,
          'requiredPaid': 100000,
        };
      default:
        return {
          'rank': '最高ランク',
          'requiredGoldStamps': 999,
          'requiredPaid': 999999,
        };
    }
  }

  // 全ランクの情報を取得
  List<Map<String, dynamic>> _getAllRanks() {
    return [
      {
        'name': 'ブロンズ',
        'requiredGoldStamps': 0,
        'requiredPaid': 0,
        'returnRate': 0.5,
      },
      {
        'name': 'シルバー',
        'requiredGoldStamps': 3,
        'requiredPaid': 5000,
        'returnRate': 1.0,
      },
      {
        'name': 'ゴールド',
        'requiredGoldStamps': 7,
        'requiredPaid': 20000,
        'returnRate': 1.5,
      },
      {
        'name': 'プラチナ',
        'requiredGoldStamps': 15,
        'requiredPaid': 50000,
        'returnRate': 2.0,
      },
      {
        'name': 'ダイヤモンド',
        'requiredGoldStamps': 30,
        'requiredPaid': 100000,
        'returnRate': 3.0,
      },
    ];
  }
} 