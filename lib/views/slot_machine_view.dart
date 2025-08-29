import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class SlotMachineView extends StatefulWidget {
  const SlotMachineView({super.key});

  @override
  State<SlotMachineView> createState() => _SlotMachineViewState();
}

class _SlotMachineViewState extends State<SlotMachineView> with TickerProviderStateMixin {
  // Firebase関連
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // スロット関連
  late AnimationController _slot1Controller;
  late AnimationController _slot2Controller;
  late AnimationController _slot3Controller;
  late Animation<double> _slot1Animation;
  late Animation<double> _slot2Animation;
  late Animation<double> _slot3Animation;
  bool _isSpinning = false;
  bool _canSpin = true;
  
  // 当選アニメーション関連
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late ConfettiController _confettiController;
  bool _showWinAnimation = false;
  
  // 1等専用のアニメーション関連
  late AnimationController _goldenAnimationController;
  late AnimationController _backgroundDimController;
  late Animation<double> _goldenGlowAnimation;
  late Animation<double> _backgroundDimAnimation;
  late ConfettiController _goldenConfettiController;
  bool _showGoldenAnimation = false;
  
  // 1等専用のポップアップ関連
  bool _showCongratulationsPopup = false;
  bool _shouldLoopConfetti = false;
  
  // 2等専用のアニメーション関連
  late AnimationController _silverAnimationController;
  late AnimationController _silverBackgroundDimController;
  late Animation<double> _silverGlowAnimation;
  late Animation<double> _silverBackgroundDimAnimation;
  late ConfettiController _silverConfettiController;
  bool _showSilverAnimation = false;
  
  // 2等専用のポップアップ関連
  bool _showSilverCongratulationsPopup = false;
  bool _shouldLoopSilverConfetti = false;
  
  // ハズレ専用のポップアップ関連
  bool _showLosePopup = false;

  
  // 結果表示
  int _result1 = 0; // 左のスロット結果 (0-9)
  int _result2 = 0; // 中央のスロット結果 (0-9)
  int _result3 = 0; // 右のスロット結果 (0-9)
  int _finalNumber = 0; // 最終的な3桁の数字 (0-999)
  int _prizeResult = 0; // 0: 未実行, 1: 1等, 2: 2等, 3: 3等(はずれ)
  bool _showResult = false;
  
  // アニメーション状態
  bool _slot1Stopped = false;
  bool _slot2Stopped = false;
  bool _slot3Stopped = false;
  
  // 手動停止用の状態
  bool _showStopButtons = false;

  @override
  void initState() {
    super.initState();
    _slot1Controller = AnimationController(
      duration: const Duration(seconds: 1), // 手動停止用に短い間隔
      vsync: this,
    );
    _slot2Controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _slot3Controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _slot1Animation = Tween<double>(
      begin: 0,
      end: 20, // より多くの回転で高速感を演出
    ).animate(CurvedAnimation(
      parent: _slot1Controller,
      curve: Curves.decelerate, // より自然な減速カーブ
    ));
    
    _slot2Animation = Tween<double>(
      begin: 0,
      end: 25, // 中央は中間の回転数
    ).animate(CurvedAnimation(
      parent: _slot2Controller,
      curve: Curves.decelerate,
    ));
    
    _slot3Animation = Tween<double>(
      begin: 0,
      end: 30, // 右端は最も多く回転
    ).animate(CurvedAnimation(
      parent: _slot3Controller,
      curve: Curves.decelerate,
    ));
    
    // 当選アニメーション初期化
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1500), // 1.5秒間放出
    );
    
    // 1等専用アニメーション初期化
    _goldenAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200), // 0.2秒間のループアニメーション
      vsync: this,
    );
    
    // 背景を薄暗くする専用コントローラー（独立）
    _backgroundDimController = AnimationController(
      duration: const Duration(milliseconds: 500), // 0.5秒で薄暗くなる
      vsync: this,
    );
    
    _goldenGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _goldenAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _backgroundDimAnimation = Tween<double>(
      begin: 0.0,
      end: 0.7, // 70%暗くする
    ).animate(CurvedAnimation(
      parent: _backgroundDimController,
      curve: Curves.easeInOut,
    ));
    
    _goldenConfettiController = ConfettiController(
      duration: const Duration(milliseconds: 2000), // 2秒間放出
    );
    
    // 2等専用アニメーション初期化
    _silverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200), // 0.2秒間のループアニメーション
      vsync: this,
    );
    
    // 2等用背景を薄暗くする専用コントローラー（独立）
    _silverBackgroundDimController = AnimationController(
      duration: const Duration(milliseconds: 500), // 0.5秒で薄暗くなる
      vsync: this,
    );
    
    _silverGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _silverAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _silverBackgroundDimAnimation = Tween<double>(
      begin: 0.0,
      end: 0.7, // 70%暗くする
    ).animate(CurvedAnimation(
      parent: _silverBackgroundDimController,
      curve: Curves.easeInOut,
    ));
    
    _silverConfettiController = ConfettiController(
      duration: const Duration(milliseconds: 2000), // 2秒間放出
    );
    
    _checkTodaysSpinStatus();
  }

  @override
  void dispose() {
    _slot1Controller.dispose();
    _slot2Controller.dispose();
    _slot3Controller.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    _goldenAnimationController.dispose();
    _backgroundDimController.dispose();
    _goldenConfettiController.dispose();
    _silverAnimationController.dispose();
    _silverBackgroundDimController.dispose();
    _silverConfettiController.dispose();
    super.dispose();
  }

  // 今日のスピン状況をチェック
  Future<void> _checkTodaysSpinStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final doc = await _firestore
          .collection('slot_history')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: dateString)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _canSpin = doc.docs.isEmpty;
    
        });
      }
    } catch (e) {
      print('スピン状況チェックエラー: $e');
    }
  }

  // スロットを開始する（手動停止式）
  Future<void> _startSlots() async {
    if (!_canSpin || _isSpinning) return;

    setState(() {
      _isSpinning = true;
      _showResult = false;
      _slot1Stopped = false;
      _slot2Stopped = false;
      _slot3Stopped = false;
      _showStopButtons = true;
    });

    // スロットアニメーションを無限ループで開始
    _slot1Controller.reset();
    _slot2Controller.reset(); 
    _slot3Controller.reset();
    
    // 無限ループアニメーション（手動停止まで継続）
    _slot1Controller.repeat();
    _slot2Controller.repeat();
    _slot3Controller.repeat();
  }

  // 個別のスロットを停止
  void _stopSlot(int slotNumber) {
    if (!_isSpinning) return;

    final random = Random();
    
    setState(() {
      switch (slotNumber) {
        case 1:
          if (!_slot1Stopped) {
            _slot1Controller.stop();
            _result1 = random.nextInt(10); // 0-9の数字をランダムで決定
            _slot1Stopped = true;
          }
          break;
        case 2:
          if (!_slot2Stopped) {
            _slot2Controller.stop();
            _result2 = random.nextInt(10);
            _slot2Stopped = true;
          }
          break;
        case 3:
          if (!_slot3Stopped) {
            _slot3Controller.stop();
            _result3 = random.nextInt(10);
            _slot3Stopped = true;
          }
          break;
      }
      
      // 全てのスロットが停止したかチェック
      if (_slot1Stopped && _slot2Stopped && _slot3Stopped) {
        _showStopButtons = false;
        _finalizeResult();
      }
    });
  }

  // 結果を確定して表示
  Future<void> _finalizeResult() async {
    // 3桁の数字を構成
    _finalNumber = _result1 * 100 + _result2 * 10 + _result3;
    
    // 当選判定（新しい条件）
    int prizeResult;
    if (_result1 == _result2 && _result2 == _result3) {
      // 1等: 3つの数字が全て同じ（ゾロ目）
      prizeResult = 1;
    } else if (_result1 == _result2 || _result2 == _result3 || _result1 == _result3) {
      // 2等: 2つの数字が同じ
      prizeResult = 2;
    } else {
      // 3等: はずれ
      prizeResult = 3;
    }

    // 結果を保存
    await _saveSlotResult(prizeResult, _finalNumber);

    setState(() {
      _prizeResult = prizeResult;
      _isSpinning = false;
      _showResult = true;
      _canSpin = false;
    });
    
    // 当選アニメーションを実行
    if (prizeResult == 1) {
      // 1等の場合は特別なゴールデンアニメーション
      _playGoldenAnimation();
    } else if (prizeResult == 2) {
      // 2等の場合は特別なシルバーアニメーション
      _playSilverAnimation();
    } else if (prizeResult == 3) {
      // ハズレの場合はハズレポップアップ
      _playLoseAnimation();
    }
  }

  // スロット結果を保存
  Future<void> _saveSlotResult(int result, int number) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      int points = 0;
      String prize = '';
      
      switch (result) {
        case 1:
          points = 10;
          prize = '1等 - 3つゾロ目 10ポイント';
          break;
        case 2:
          points = 3;
          prize = '2等 - 2つ同じ 3ポイント';
          break;
        case 3:
          points = 0;
          prize = 'はずれ';
          break;
      }

      // トランザクションでポイント更新と履歴保存を同時実行
      await _firestore.runTransaction((transaction) async {
        // ユーザーのポイントを更新
        if (points > 0) {
          final userRef = _firestore.collection('users').doc(user.uid);
          final userDoc = await transaction.get(userRef);
          
          if (userDoc.exists) {
            final currentPoints = userDoc.data()?['points'] ?? 0;
            transaction.update(userRef, {
              'points': currentPoints + points,
            });
          }
        }
        
        // スロット履歴を保存
        final historyRef = _firestore.collection('slot_history').doc();
        transaction.set(historyRef, {
          'userId': user.uid,
          'date': dateString,
          'result': result,
          'number': number,
          'points': points,
          'prize': prize,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // ポイント履歴にも追加（ポイントがある場合のみ）
        if (points > 0) {
          final pointHistoryRef = _firestore.collection('user_stamps').doc();
          transaction.set(pointHistoryRef, {
            'userId': user.uid,
            'storeName': 'スロット',
            'points': points,
            'createdAt': FieldValue.serverTimestamp(),
            'type': 'スロット',
            'description': prize,
          });
        }
      });

      print('スロット結果保存成功: $prize');
    } catch (e) {
      print('スロット結果保存エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showCongratulationsPopup && !_showSilverCongratulationsPopup && !_showLosePopup, // ポップアップ表示中は戻れない
      child: Scaffold(
      backgroundColor: _showGoldenAnimation 
          ? Color.lerp(
              const Color(0xFFF5F5F5),
              Colors.grey[800]!,
              _backgroundDimAnimation.value,
            )
          : _showSilverAnimation
            ? Color.lerp(
                const Color(0xFFF5F5F5),
                Colors.grey[800]!,
                _silverBackgroundDimAnimation.value,
              )
            : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'スロットマシン',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // メインコンテンツ
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - kToolbarHeight,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              const SizedBox(height: 20),
              
              // タイトル
              const Text(
                '🎰 3桁スロット 🎰',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 10),
              
              // 説明
              Text(
                '1日1回チャレンジ！\n1等: 3つゾロ目 (10pt)\n2等: 2つ同じ (3pt)',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // スロットマシン
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1等時の追加の明るいリング
                      if (_showGoldenAnimation)
                        AnimatedBuilder(
                          animation: _goldenGlowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 440,
                              height: 240,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(
                                    ((sin(_goldenGlowAnimation.value * 20) + 1) / 2) * 0.8
                                  ),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(
                                      ((sin(_goldenGlowAnimation.value * 20) + 1) / 2) * 0.5
                                    ),
                                    spreadRadius: 10,
                                    blurRadius: 20,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      // 2等時の追加の明るいリング
                      if (_showSilverAnimation)
                        AnimatedBuilder(
                          animation: _silverGlowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 440,
                              height: 240,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.grey[400]!.withOpacity(
                                    ((sin(_silverGlowAnimation.value * 20) + 1) / 2) * 0.8
                                  ),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey[400]!.withOpacity(
                                      ((sin(_silverGlowAnimation.value * 20) + 1) / 2) * 0.5
                                    ),
                                    spreadRadius: 10,
                                    blurRadius: 20,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      // メインのスロットマシン
                      Container(
                        width: 400,
                        height: 200,
                    decoration: BoxDecoration(
                      color: _showGoldenAnimation || _showSilverAnimation ? Colors.black : Colors.black87, // 1等・2等時はより濃い背景
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _showGoldenAnimation
                          ? Color.lerp(
                              const Color(0xFFFFD700), // ゴールド
                              Colors.white,
                              (sin(_goldenGlowAnimation.value * 10) + 1) / 2, // 点滅効果
                            )!
                          : _showSilverAnimation
                            ? Color.lerp(
                                const Color(0xFFC0C0C0), // シルバー
                                Colors.white,
                                (sin(_silverGlowAnimation.value * 10) + 1) / 2, // 点滅効果
                              )!
                            : _showWinAnimation 
                              ? Color.lerp(
                                  const Color(0xFFFF6B35),
                                  Colors.yellow,
                                  _glowAnimation.value,
                                )!
                              : const Color(0xFFFF6B35),
                        width: _showGoldenAnimation || _showSilverAnimation ? 6 : 4, // 1等・2等の場合はより太く
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                        if (_showGoldenAnimation)
                          BoxShadow(
                            color: Color(0xFFFFD700).withOpacity(
                              ((sin(_goldenGlowAnimation.value * 10) + 1) / 2) * 0.9
                            ), // 点滅するゴールドの影
                            spreadRadius: _goldenGlowAnimation.value * 25, // より強い光
                            blurRadius: _goldenGlowAnimation.value * 50, // より大きな光
                            offset: const Offset(0, 0),
                          ),
                        if (_showSilverAnimation)
                          BoxShadow(
                            color: Color(0xFFC0C0C0).withOpacity(
                              ((sin(_silverGlowAnimation.value * 10) + 1) / 2) * 0.9
                            ), // 点滅するシルバーの影
                            spreadRadius: _silverGlowAnimation.value * 25, // より強い光
                            blurRadius: _silverGlowAnimation.value * 50, // より大きな光
                            offset: const Offset(0, 0),
                          ),
                        if (_showWinAnimation && !_showGoldenAnimation && !_showSilverAnimation)
                          BoxShadow(
                            color: Colors.yellow.withOpacity(_glowAnimation.value * 0.8),
                            spreadRadius: _glowAnimation.value * 15,
                            blurRadius: _glowAnimation.value * 30,
                            offset: const Offset(0, 0),
                          ),
                      ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 左のスロット
                            _buildSlotReel(_slot1Animation, _result1, 1, _slot1Stopped),
                            
                            // 区切り線
                            Container(
                              width: 2,
                              height: 120,
                              color: const Color(0xFFFF6B35),
                            ),
                            
                            // 中央のスロット
                            _buildSlotReel(_slot2Animation, _result2, 2, _slot2Stopped),
                            
                            // 区切り線
                            Container(
                              width: 2,
                              height: 120,
                              color: const Color(0xFFFF6B35),
                            ),
                            
                            // 右のスロット
                            _buildSlotReel(_slot3Animation, _result3, 3, _slot3Stopped),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // 停止ボタン
              if (_showStopButtons)
                Column(
                  children: [
                    const Text(
                      '各スロットを停止してください',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 左スロット停止ボタン
                        _buildStopButton(1, _slot1Stopped),
                        // 中央スロット停止ボタン
                        _buildStopButton(2, _slot2Stopped),
                        // 右スロット停止ボタン
                        _buildStopButton(3, _slot3Stopped),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              
              // スピンボタン
              ElevatedButton(
                onPressed: _canSpin && !_isSpinning ? _startSlots : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSpin && !_isSpinning 
                      ? const Color(0xFFFF6B35)
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  _isSpinning 
                      ? '各スロットを停止してください'
                      : _canSpin
                          ? 'スタート！'
                          : '明日また挑戦！',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // テスト用ボタン（開発用）
              ElevatedButton(
                onPressed: _testGoldenAnimation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700), // ゴールド色
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  '🎰 1等アニメーションテスト',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // 2等テスト用ボタン
              ElevatedButton(
                onPressed: _testSecondPlaceAnimation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0C0C0), // シルバー色
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  '🎰 2等アニメーションテスト',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // ハズレテスト用ボタン
              ElevatedButton(
                onPressed: _testLoseAnimation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF757575), // グレー色
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  '🎰 ハズレアニメーションテスト',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // 状態表示
              if (!_canSpin && !_showResult) ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    '今日はもうスピンしました！\n明日また挑戦してください。',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
                ],
              ),
            ),
          ),
          
          // 紙吹雪アニメーション
          if (_showWinAnimation)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 90 * (3.14159 / 180), // 下方向
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.02, // 空気抵抗を減らして長く浮遊
                emissionFrequency: 0.05, // 放出頻度を上げて密度アップ
                numberOfParticles: 240, // パーティクル数を増加
                gravity: 0.2, // 重力を弱くしてゆっくり落下
                shouldLoop: false,
                maxBlastForce: 25, // 爆発力を増加
                minBlastForce: 8,
                colors: const [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                  Colors.pink,
                  Colors.cyan,
                  Colors.amber,
                ],
              ),
            ),
          

          
          // 1等専用: 金色の紙吹雪アニメーション
          if (_showGoldenAnimation)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _goldenConfettiController,
                blastDirection: 90 * (3.14159 / 180), // 下方向
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.01, // より長く浮遊
                emissionFrequency: 0.03, // より高密度
                numberOfParticles: 360, // より多くのパーティクル（3倍）
                gravity: 0.15, // よりゆっくり落下
                shouldLoop: false,
                maxBlastForce: 30, // より強い爆発力
                minBlastForce: 10,
                colors: const [
                  Color(0xFFFFD700), // ゴールド
                  Color(0xFFFFE55C), // ライトゴールド
                  Color(0xFFFFC72C), // ダークゴールド
                  Color(0xFFFFB347), // オレンジゴールド
                  Color(0xFFDAA520), // ゴールデンロッド
                  Color(0xFFB8860B), // ダークゴールデンロッド
                ],
              ),
            ),
          
          // 2等専用: シルバーの紙吹雪アニメーション
          if (_showSilverAnimation)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _silverConfettiController,
                blastDirection: 90 * (3.14159 / 180), // 下方向
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.01, // より長く浮遊
                emissionFrequency: 0.03, // より高密度
                numberOfParticles: 360, // より多くのパーティクル（3倍）
                gravity: 0.15, // よりゆっくり落下
                shouldLoop: false,
                maxBlastForce: 30, // より強い爆発力
                minBlastForce: 10,
                colors: const [
                  Color(0xFFC0C0C0), // シルバー
                  Color(0xFFD3D3D3), // ライトグレー
                  Color(0xFFA9A9A9), // ダークグレー
                  Color(0xFFDCDCDC), // ガイスボロー
                  Color(0xFFB0C4DE), // ライトスチールブルー
                  Color(0xFF708090), // スレートグレー
                ],
              ),
            ),
          
          // 1等専用: おめでとうポップアップ（モーダル）
          if (_showCongratulationsPopup) ...[
            // 背面をタッチできないようにするバリア
            ModalBarrier(
              dismissible: false, // タップしても閉じない
              color: Colors.transparent, // 既に背景が暗くなっているので透明
            ),
            // ポップアップ本体
            Center(
              child: Container(
                width: 320,
                height: 240,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD700), // ゴールド
                      Color(0xFFFFA500), // オレンジ
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🎉',
                      style: TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '1等当選おめでとう！',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '10ポイント獲得',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // 確認ボタン
                    ElevatedButton(
                      onPressed: () {
                        // 1等アニメーションを停止
                        _stopGoldenAnimation();
                        // home_view.dartに戻る
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        '確認',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // 2等専用: おめでとうポップアップ（モーダル）
          if (_showSilverCongratulationsPopup) ...[
            // 背面をタッチできないようにするバリア
            ModalBarrier(
              dismissible: false, // タップしても閉じない
              color: Colors.transparent, // 既に背景が暗くなっているので透明
            ),
            // ポップアップ本体
            Center(
              child: Container(
                width: 320,
                height: 240,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFC0C0C0), // シルバー
                      Color(0xFF808080), // グレー
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🎉',
                      style: TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '2等当選おめでとう！',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '3ポイント獲得',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // 確認ボタン
                    ElevatedButton(
                      onPressed: () {
                        // 2等アニメーションを停止
                        _stopSilverAnimation();
                        // home_view.dartに戻る
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        '確認',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // ハズレ専用: ポップアップ（モーダル）
          if (_showLosePopup) ...[
            // 背面をタッチできないようにするバリア
            ModalBarrier(
              dismissible: false, // タップしても閉じない
              color: Colors.black.withOpacity(0.3), // 軽く暗くする
            ),
            // ポップアップ本体
            Center(
              child: Container(
                width: 320,
                height: 240,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF757575), // グレー
                      Color(0xFF424242), // ダークグレー
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '😢',
                      style: TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ハズレ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'また明日挑戦してください！',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // 確認ボタン
                    ElevatedButton(
                      onPressed: () {
                        // ハズレポップアップを閉じる
                        setState(() {
                          _showLosePopup = false;
                        });
                        // home_view.dartに戻る
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        '確認',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  // スロットリールを構築（リアルなスクロールアニメーション）
  Widget _buildSlotReel(Animation<double> animation, int result, int slotNumber, bool isStopped) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        bool shouldAnimate = _isSpinning && !isStopped;
        
        return Container(
          width: 90,
          height: 120,
          decoration: BoxDecoration(
            color: isStopped ? Colors.green[50] : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isStopped ? Colors.green : const Color(0xFFFF6B35),
              width: isStopped ? 3 : 2,
            ),
            boxShadow: isStopped ? [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // スロットの数字スクロールエフェクト
                if (shouldAnimate)
                  _buildScrollingNumbers(animation, slotNumber)
                else
                  _buildStaticNumber(result, isStopped),
                
                // 停止時のエフェクト
                if (isStopped)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                
                // スロットマシンの窓枠効果
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          shouldAnimate ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          Colors.transparent,
                          shouldAnimate ? Colors.black.withOpacity(0.1) : Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // スクロールする数字列を描画
  Widget _buildScrollingNumbers(Animation<double> animation, int slotNumber) {
    // 各スロットで異なる回転速度を設定
    double speed = 1.0;
    switch (slotNumber) {
      case 1:
        speed = 3.0; // 左が最も速い
        break;
      case 2:
        speed = 2.5; // 中央
        break;
      case 3:
        speed = 2.0; // 右が最も遅い
        break;
    }
    
    double animationValue = animation.value * speed;
    double scrollOffset = (animationValue * 60) % 600; // 数字の高さの10倍でループ
    
    return Container(
      height: 120,
      child: Stack(
        children: [
          // 連続する数字列を表示（0-9を複数回繰り返す）
          for (int cycle = -1; cycle <= 10; cycle++)
            for (int digit = 0; digit <= 9; digit++)
              Positioned(
                left: 0,
                right: 0,
                top: (cycle * 10 + digit) * 60.0 - scrollOffset,
                child: Container(
                  height: 60,
                  child: Center(
                    child: Text(
                      digit.toString(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          
          // 上下にフェードエフェクトを追加（リアルな窓効果）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 静止した数字を表示
  Widget _buildStaticNumber(int number, bool isStopped) {
    return Center(
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(
          fontSize: isStopped ? 52 : 48,
          fontWeight: FontWeight.bold,
          color: isStopped ? Colors.green[700] : Colors.black87,
          fontFamily: 'monospace',
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Text(number.toString()),
      ),
    );
  }

  // 停止ボタンを構築
  Widget _buildStopButton(int slotNumber, bool isStopped) {
    return ElevatedButton(
      onPressed: isStopped ? null : () => _stopSlot(slotNumber),
      style: ElevatedButton.styleFrom(
        backgroundColor: isStopped ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isStopped ? Icons.check_circle : Icons.stop,
            size: 20,
          ),
          const SizedBox(height: 2),
          Text(
            isStopped ? '停止済' : 'ストップ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  

  
  // 1等専用ゴールデンアニメーションを実行
  void _playGoldenAnimation() {
    // ゴールデンアニメーション開始
    setState(() {
      _showGoldenAnimation = true;
    });
    
    // 背景を薄暗くするアニメーション開始（確認ボタンが押されるまで継続）
    _backgroundDimController.forward();
    
    // ループアニメーション開始（確認ボタンが押されるまで継続）
    _goldenAnimationController.repeat();
    
    // 金色紙吹雪アニメーション開始（少し遅らせて開始、ループ継続）
    Future.delayed(const Duration(milliseconds: 500), () {
      _startLoopingConfetti();
    });
    
    // 1.5秒後におめでとうポップアップを表示
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showCongratulationsPopup = true;
        });
      }
    });
  }
  
  // 1等アニメーションを停止
  void _stopGoldenAnimation() {
    setState(() {
      _showGoldenAnimation = false;
      _showCongratulationsPopup = false;
      _shouldLoopConfetti = false;
    });
    _goldenAnimationController.stop();
    _goldenAnimationController.reset();
    _backgroundDimController.reverse(); // 背景を元の明るさに戻す
    _goldenConfettiController.stop();
  }
  
  // 紙吹雪をループさせる
  void _startLoopingConfetti() {
    if (!mounted) return;
    
    setState(() {
      _shouldLoopConfetti = true;
    });
    
    _goldenConfettiController.play();
    
    // 3秒後に再度紙吹雪を開始（ループ効果）
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (_shouldLoopConfetti && mounted) {
        _startLoopingConfetti();
      }
    });
  }
  
  // 2等専用シルバーアニメーションを実行
  void _playSilverAnimation() {
    // シルバーアニメーション開始
    setState(() {
      _showSilverAnimation = true;
    });
    
    // 背景を薄暗くするアニメーション開始（確認ボタンが押されるまで継続）
    _silverBackgroundDimController.forward();
    
    // ループアニメーション開始（確認ボタンが押されるまで継続）
    _silverAnimationController.repeat();
    
    // シルバー紙吹雪アニメーション開始（少し遅らせて開始、ループ継続）
    Future.delayed(const Duration(milliseconds: 500), () {
      _startLoopingSilverConfetti();
    });
    
    // 1.5秒後におめでとうポップアップを表示
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showSilverCongratulationsPopup = true;
        });
      }
    });
  }
  
  // 2等アニメーションを停止
  void _stopSilverAnimation() {
    setState(() {
      _showSilverAnimation = false;
      _showSilverCongratulationsPopup = false;
      _shouldLoopSilverConfetti = false;
    });
    _silverAnimationController.stop();
    _silverAnimationController.reset();
    _silverBackgroundDimController.reverse(); // 背景を元の明るさに戻す
    _silverConfettiController.stop();
  }
  
  // 2等用シルバー紙吹雪をループさせる
  void _startLoopingSilverConfetti() {
    if (!mounted) return;
    
    setState(() {
      _shouldLoopSilverConfetti = true;
    });
    
    _silverConfettiController.play();
    
    // 3秒後に再度紙吹雪を開始（ループ効果）
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (_shouldLoopSilverConfetti && mounted) {
        _startLoopingSilverConfetti();
      }
    });
  }
  
  // テスト用: 1等アニメーションを手動実行
  void _testGoldenAnimation() {
    setState(() {
      _prizeResult = 1; // 1等に設定
      _showResult = true;
      _finalNumber = 777; // テスト用の数字
    });
    _playGoldenAnimation();
  }
  
  // テスト用: 2等アニメーションを手動実行
  void _testSecondPlaceAnimation() {
    setState(() {
      _prizeResult = 2; // 2等に設定
      _showResult = true;
      _finalNumber = 711; // テスト用の数字（2つ同じ数字）
    });
    _playSilverAnimation();
  }
  
  // ハズレアニメーションを実行
  void _playLoseAnimation() {
    // ハズレポップアップをすぐに表示
    setState(() {
      _showLosePopup = true;
    });
  }
  
  // テスト用: ハズレアニメーションを手動実行
  void _testLoseAnimation() {
    setState(() {
      _prizeResult = 3; // ハズレに設定
      _showResult = true;
      _finalNumber = 123; // テスト用の数字（バラバラ）
    });
    _playLoseAnimation();
  }
}


