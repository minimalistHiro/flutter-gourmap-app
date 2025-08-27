import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GetPointView extends StatefulWidget {
  final Function(bool) onGetPointViewChanged;
  final Function(int) onTabChanged;
  
  const GetPointView({
    super.key,
    required this.onGetPointViewChanged,
    required this.onTabChanged,
  });

  @override
  State<GetPointView> createState() => _GetPointViewState();
}

class _GetPointViewState extends State<GetPointView> with TickerProviderStateMixin {
  int currentTab = 0; // 0: Page1, 1: Page2
  int stampCount = 4;
  int flower = 7;
  int paid = 4000;
  int getFlower = 3;
  int getPaid = 3000;
  
  late AnimationController _flowerAnimationController;
  late AnimationController _paidAnimationController;
  late Animation<int> _flowerAnimation;
  late Animation<int> _paidAnimation;

  @override
  void initState() {
    super.initState();
    
    // アニメーションコントローラーの初期化
    _flowerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _paidAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    // アニメーションの設定
    _flowerAnimation = IntTween(
      begin: flower,
      end: flower + getFlower,
    ).animate(CurvedAnimation(
      parent: _flowerAnimationController,
      curve: Curves.easeOut,
    ));
    
    _paidAnimation = IntTween(
      begin: paid,
      end: paid + getPaid,
    ).animate(CurvedAnimation(
      parent: _paidAnimationController,
      curve: Curves.easeOut,
    ));
    
    // アニメーション開始
    _startAnimations();
  }

  @override
  void dispose() {
    _flowerAnimationController.dispose();
    _paidAnimationController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    _flowerAnimationController.forward();
    _paidAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: IndexedStack(
          index: currentTab,
          children: [
            _buildPage1(),
            _buildPage2(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return Column(
      children: [
        const SizedBox(height: 30),
        
        // タイトル
        const Text(
          'アイテム獲得！',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const Spacer(),
        
        // ポイント表示
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.store,
                size: 30,
                color: Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(width: 20),
            Row(
              children: [
                const Text(
                  '30',
                  style: TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'pt',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // フラワー表示
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.pink[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_florist,
                size: 50,
                color: Colors.pink,
              ),
            ),
            const SizedBox(width: 20),
            AnimatedBuilder(
              animation: _flowerAnimation,
              builder: (context, child) {
                return Text(
                  '×${_flowerAnimation.value}',
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // 支払い額表示
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.attach_money,
                size: 50,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 20),
            AnimatedBuilder(
              animation: _paidAnimation,
              builder: (context, child) {
                return Text(
                  '${_paidAnimation.value}円',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
        
        const Spacer(),
        
        // ランク情報カード
        Container(
          width: 320,
          height: 170,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 現在のランク
                Row(
                  children: [
                    const Text(
                      'ランク： ',
                      style: TextStyle(fontSize: 17),
                    ),
                    const Text(
                      'ブルー',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.emoji_events,
                      size: 18,
                      color: Color(0xFF1E88E5),
                    ),
                  ],
                ),
                
                const Divider(),
                
                // 次のランク
                Row(
                  children: [
                    const Text(
                      '次のランク（',
                      style: TextStyle(fontSize: 14),
                    ),
                    const Text(
                      'グリーン',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.emoji_events,
                      size: 14,
                      color: Colors.green,
                    ),
                    const Text(
                      ')まで',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // フラワープログレスバー
                _buildTimerRankBar(
                  icon: Icons.local_florist,
                  title: 'フラワー',
                  unit: '個',
                  currentValue: flower,
                  maxValue: 20,
                  color: Colors.pink,
                ),
                
                const SizedBox(height: 8),
                
                // 支払い額プログレスバー
                _buildTimerRankBar(
                  icon: Icons.attach_money,
                  title: '総支払い額',
                  unit: '円',
                  currentValue: paid,
                  maxValue: 10000,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
        
        const Spacer(),
        
        // 次へボタン
        GestureDetector(
          onTap: () {
            setState(() {
              currentTab = 1;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              '次へ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const Spacer(),
      ],
    );
  }

  Widget _buildPage2() {
    return Column(
      children: [
        const SizedBox(height: 20),
        
        // 店舗情報
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.store,
                size: 20,
                color: Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Antenna Books & Cafe ココシバ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 30),
        
        // タイトル
        const Text(
          'スタンプ獲得！',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const Spacer(),
        
        // スタンプカード
        _buildStampCard(),
        
        const Spacer(),
        
        // 終了ボタン
        GestureDetector(
          onTap: () {
            widget.onGetPointViewChanged(false);
            widget.onTabChanged(1); // ホームタブに戻る
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              '終了',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const Spacer(),
      ],
    );
  }

  Widget _buildTimerRankBar({
    required IconData icon,
    required String title,
    required String unit,
    required int currentValue,
    required int maxValue,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: color,
          ),
        ),
        const Spacer(),
        Text(
          '$currentValue$unit / $maxValue$unit',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: currentValue / maxValue,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              currentValue >= maxValue ? Colors.green : color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStampCard() {
    return Container(
      width: 300,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'スタンプカード',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // スタンプ表示
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  bool isCollected = index < stampCount;
                  return Container(
                    decoration: BoxDecoration(
                      color: isCollected ? Colors.orange : Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCollected ? Colors.orange : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isCollected
                        ? const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 10),
            Text(
              '$stampCount/10 スタンプ',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 