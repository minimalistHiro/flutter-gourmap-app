import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FriendIntroView extends StatefulWidget {
  const FriendIntroView({super.key});

  @override
  State<FriendIntroView> createState() => _FriendIntroViewState();
}

class _FriendIntroViewState extends State<FriendIntroView> {
  bool isShowCopyMessage = false;
  String friendIntroCode = "3dur8iK0";

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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 友達紹介画像
                Container(
                  width: double.infinity,
                  height: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.people,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // タイトルテキスト
                const Text(
                  '友達を紹介すると、双方に',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5), // blueGreen
                  ),
                ),
                const Text(
                  'フラワー30個もらえる！',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5), // blueGreen
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // 紹介コードタイトル
                const Text(
                  '金子広樹さんの紹介コード',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // 紹介コードカード
                Container(
                  width: 300,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blue,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      Text(
                        friendIntroCode,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 30),
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
                        child: const Icon(
                          Icons.copy,
                          size: 24,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 30),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // 友達にシェアボタン
                _buildCustomCapsule(
                  text: '友達にシェア',
                  foregroundColor: Colors.blue,
                  textColor: Colors.white,
                  isStroke: false,
                  onTap: () {
                    // シェア機能（後で実装）
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('シェア機能を実装予定')),
                    );
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
                  title: '友達にストコポ加盟店を3店舗以上買い物してもらう',
                  text: '決済時、当アプリのポイントを貯めるとカウントされます。',
                  imageName: 'SmartPhoneQRCode',
                ),
                
                // ステップ4
                _buildStepView(
                  step: 4,
                  title: '紹介者、友達の双方にフラワー30個付与',
                  text: '',
                  imageName: 'Flower',
                ),
                
                const SizedBox(height: 20),
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