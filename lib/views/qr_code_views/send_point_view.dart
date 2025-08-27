import 'package:flutter/material.dart';
import 'success_send_view.dart';

class SendPointView extends StatefulWidget {
  final bool isStoreOwner;
  final Function(bool) onSendPayChanged;
  
  const SendPointView({
    super.key,
    required this.isStoreOwner,
    required this.onSendPayChanged,
  });

  @override
  State<SendPointView> createState() => _SendPointViewState();
}

class _SendPointViewState extends State<SendPointView> {
  String sendPointText = "0";
  bool isShowSendPointAlert = false;
  
  final List<String> keyboard = ["7", "8", "9", "4", "5", "6", "1", "2", "3", "0", "00", "AC"];

  // ボタン共通スタイル（円形）
  Widget _buildCalcButton({required String label, required VoidCallback onTap, Color? color}) {
    final bool isDestructive = label == 'AC';
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50, // 70から50に変更
          margin: const EdgeInsets.symmetric(horizontal: 4), // 6から4に変更
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18, // 24から18に変更
                fontWeight: FontWeight.bold,
                color: isDestructive ? Colors.red : (color ?? Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalcButtonEmpty() {
    return const Expanded(child: SizedBox.shrink());
  }

  Widget _buildCalcRow(List<String> labels) {
    return Row(
      children: labels.map((label) {
        if (label == 'AC') {
          return _buildCalcButton(label: label, onTap: () => _apply('AC'), color: Colors.red);
        }
        if (label == '⌫') {
          return _buildCalcButton(label: label, onTap: _backspace, color: Colors.black87);
        }
        return _buildCalcButton(label: label, onTap: () => _apply(label));
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
              backgroundColor: const Color(0xFFFF6B35), // GourMap color
      body: SafeArea(
        child: Stack(
          children: [

            
            // メインコンテンツ
            Column(
              children: [
                const SizedBox(height: 40),
                
                // 戻るボタン
                Row(
                  children: [
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // トップ画像
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store,
                    size: 40,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // 店舗名
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Antenna Books & Cafe ココシバ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (!widget.isStoreOwner) ...[
                      const SizedBox(width: 5),
                      const Text(
                        'に支払う',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 5),
                
                // 説明文
                Text(
                  widget.isStoreOwner 
                    ? '↓お客様のお会計額を入力してください↓'
                    : '保有ポイント：250pt',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                
                const Spacer(),
                
                // 金額表示
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      sendPointText,
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isStoreOwner ? '円' : 'pt',
                      style: const TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                const Spacer(),
                
                // 送るボタン
                Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        int amount = int.tryParse(sendPointText) ?? 0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('0より大きい数字を入力してください。'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        _showConfirmDialog();
                      },
                      child: Container(
                        width: 100,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (int.tryParse(sendPointText) ?? 0) <= 0 
                            ? Colors.grey 
                            : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            widget.isStoreOwner ? '確定' : '送る',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: (int.tryParse(sendPointText) ?? 0) <= 0 
                                ? Colors.grey[600] 
                                : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (!widget.isStoreOwner)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            sendPointText = "250";
                          });
                        },
                        child: const Text(
                          '全てのポイント',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(width: 20),
                  ],
                ),
                
                const Spacer(),
                
                // キーパッド（電卓風）
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 4), // 8から4に変更
                      _buildCalcRow(['7', '8', '9', 'AC']),
                      const SizedBox(height: 8), // 12から8に変更
                      _buildCalcRow(['4', '5', '6', '⌫']),
                      const SizedBox(height: 8), // 12から8に変更
                      _buildCalcRow(['1', '2', '3', '00']),
                      const SizedBox(height: 8), // 12から8に変更
                      Row(
                        children: [
                          _buildCalcButton(label: '0', onTap: () => _apply('0')),
                          _buildCalcButtonEmpty(),
                          _buildCalcButtonEmpty(),
                          _buildCalcButtonEmpty(),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10), // 20から10に変更
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _apply(String key) {
    if (key == "AC") {
      setState(() {
        sendPointText = "0";
      });
    } else if (key == '⌫') {
      _backspace();
    } else if (int.tryParse(key) != null) {
      _tappedNumberPadProcess(key);
    }
  }

  void _backspace() {
    setState(() {
      if (sendPointText.isEmpty || sendPointText == '0') {
        sendPointText = '0';
      } else if (sendPointText.length == 1) {
        sendPointText = '0';
      } else {
        sendPointText = sendPointText.substring(0, sendPointText.length - 1);
      }
    });
  }

  void _tappedNumberPadProcess(String key) {
    if (sendPointText == "0" && (key == "0" || key == "00")) {
      return;
    }
    
    setState(() {
      if (sendPointText == "0") {
        if (key == "00") {
          sendPointText = "0";
        } else {
          sendPointText = key;
        }
      } else {
        // 最大桁数チェック（8桁）
        if ((sendPointText + key).length <= 8) {
          sendPointText += key;
        }
      }
    });
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.isStoreOwner ? '確定しますか？' : ''),
          content: Text(
            widget.isStoreOwner 
              ? '確定後、相手にランクに応じたポイントが付与されます。'
              : '${sendPointText}pt送りますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // SuccessSendViewに遷移
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => SuccessSendView(
                      isStoreOwner: widget.isStoreOwner,
                      onReturn: () {
                        Navigator.of(context).pop();
                        widget.onSendPayChanged(true);
                      },
                    ),
                  ),
                );
              },
              child: Text(widget.isStoreOwner ? '送る' : '確定'),
            ),
          ],
        );
      },
    );
  }
} 