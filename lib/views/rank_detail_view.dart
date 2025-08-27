import 'package:flutter/material.dart';

class RankDetailView extends StatefulWidget {
  const RankDetailView({super.key});

  @override
  State<RankDetailView> createState() => _RankDetailViewState();
}

class _RankDetailViewState extends State<RankDetailView> {
  int stamp = 10;
  int paid = 10000;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // ヘッダー画像
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.person,
                size: 80,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // タイトル
            const Text(
              'ランクを上げて、',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
            const Text(
              'ポイント還元率を上げよう！',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 現在のランクカード
            _buildCurrentRankCard(),
            
            const SizedBox(height: 10),
            
            // 次のランクカード
            _buildNextRankCard(),
            
            const SizedBox(height: 30),
            
            // ランクについてセクション
            _buildRankAboutSection(),
            
            const SizedBox(height: 20),
            
            // ランク一覧
            _buildRankList(),
            
            const SizedBox(height: 20),
            
            // ランクを上げるにはセクション
            _buildHowToRankUpSection(),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentRankCard() {
    return Container(
      width: 300,
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(3),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ヘッダー部分
              Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '金子広樹さんの現在のランク',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // ランク表示部分
              Row(
                children: [
                  const Spacer(),
                  // 現在のランク
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ブルー',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.emoji_events,
                          size: 24,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  
                  // 矢印
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 15),
                  
                  // 次のランク
                  Column(
                    children: [
                      const Text(
                        '次のランク',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'グリーン',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.emoji_events,
                              size: 14,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 還元率表示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Color(0xFFFF6B35),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ポイント還元率：',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      '0.5%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextRankCard() {
    return Container(
      width: 320,
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(3),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ヘッダー部分
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Color(0xFF4CAF50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '次のランク（グリーン）まで',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'グリーン',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // プログレスバー
              _buildRankBar('フラワー', stamp, 20, Icons.local_florist, '個', Colors.pink),
              const SizedBox(height: 12),
              _buildRankBar('総支払い額', paid, 10000, Icons.attach_money, '円', Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankBar(String title, int value, int maxValue, IconData icon, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: value / maxValue,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$value$unit / $maxValue$unit',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 30),
          child: Text(
            'ランクについて',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            'ブルーからブラックまで、合計10のランクがあります。ランクが上がるたびに、ポイント還元率がUPします！',
            style: TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRankList() {
    final ranks = [
      {'name': 'ブルー', 'color': const Color(0xFF1E88E5), 'rate': 0.5, 'isCurrent': true},
      {'name': 'グリーン', 'color': Colors.green, 'rate': 0.7, 'isCurrent': false},
      {'name': 'イエロー', 'color': Colors.yellow, 'rate': 1.0, 'isCurrent': false},
      {'name': 'オレンジ', 'color': Colors.orange, 'rate': 1.2, 'isCurrent': false},
      {'name': 'レッド', 'color': Colors.red, 'rate': 1.5, 'isCurrent': false},
      {'name': 'パープル', 'color': Colors.purple, 'rate': 1.8, 'isCurrent': false},
      {'name': 'ブロンズ', 'color': Colors.brown, 'rate': 2.5, 'isCurrent': false},
      {'name': 'シルバー', 'color': Colors.grey, 'rate': 3.0, 'isCurrent': false},
      {'name': 'ゴールド', 'color': const Color(0xFFFFD700), 'rate': 5.0, 'isCurrent': false},
      {'name': 'ブラック', 'color': Colors.black, 'rate': 10.0, 'isCurrent': false},
    ];

    return Column(
      children: ranks.map((rank) => _buildRankRow(
        rank['name'] as String,
        rank['color'] as Color,
        rank['rate'] as double,
        rank['isCurrent'] as bool,
      )).toList(),
    );
  }

  Widget _buildRankRow(String colorName, Color color, double pointRate, bool isNowRank) {
    return Container(
      width: 320,
      height: isNowRank ? 70 : 60,
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: isNowRank ? const Color(0xFFFFEB3B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNowRank)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '現在のランク',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 30,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      colorName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'ポイント還元率：${pointRate.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToRankUpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 30),
          child: Text(
            'ランクを上げるには？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            'ランクは、フラワーと総支払額の両方が基準値に達すると、次のランクへと昇格します。',
            style: TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 20),
        
        // フラワー獲得方法カード
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'フラワーを獲得するには？',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.pink[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_florist,
                    size: 40,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 30),
                _buildMethodView(1, 'ストコポ対応店で買い物をして、ポイントを貯める', 'ストコポ対応店で買い物をすることで、フラワーを5個獲得できます。', Icons.qr_code),
                _buildMethodView(2, '1日1回限定ガチャを回す', 'フラワーを最大3個獲得できます。', Icons.casino),
                _buildMethodView(3, '友達を紹介する', '友達紹介で、紹介者、友達の双方にフラワー30個もらえます。', Icons.people),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodView(int method, String title, String text, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '方法$method',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 35,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
} 