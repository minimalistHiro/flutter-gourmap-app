import 'package:flutter/material.dart';
import 'ranking_data_view.dart';

class RankingListView extends StatefulWidget {
  const RankingListView({super.key});

  @override
  State<RankingListView> createState() => _RankingListViewState();
}

class _RankingListViewState extends State<RankingListView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFACD), // 金色のグラデーション背景
      appBar: AppBar(
        title: const Text(
          'ランキング',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFFACD),
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
            
            // メダル画像
            Container(
              height: 200,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Image.asset(
                'assets/images/medal_icon.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.emoji_events,
                    size: 150,
                    color: Colors.amber,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 15),
            
            // タイトルテキスト
            const Text(
              'さまざまなランキングを',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const Text(
              '見てみよう！',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 説明テキスト
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'このページでは、さまざまなランキングを掲載しています。自分がどのくらいの位置にいるか、見てみましょう。',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // ランキング項目
            _buildRankDetailView(
              icon: Icons.local_florist,
              title: 'スタンプ数',
              unit: '個',
            ),
            
            _buildRankDetailView(
              icon: Icons.attach_money,
              title: '総支払い額',
              unit: '円',
            ),
            
            _buildRankDetailView(
              icon: Icons.store,
              title: '利用店舗数',
              unit: '店',
            ),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildRankDetailView({
    required IconData icon,
    required String title,
    required String unit,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RankingDataView(
              category: title,
              unit: unit,
            ),
          ),
        );
      },
      child: Container(
        width: 320,
        height: 80,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(
              icon,
              size: 40,
              color: Colors.amber,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                '${title}ランキング',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
} 