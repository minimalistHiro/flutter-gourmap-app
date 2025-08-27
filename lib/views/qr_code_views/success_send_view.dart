import 'package:flutter/material.dart';

class SuccessSendView extends StatelessWidget {
  final bool isStoreOwner;
  final Function() onReturn;
  
  const SuccessSendView({
    super.key,
    required this.isStoreOwner,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              
              // チェックマークアイコン
              Icon(
                Icons.check_circle,
                size: 60,
                color: isStoreOwner ? Colors.green : const Color(0xFF1E88E5),
              ),
              const SizedBox(height: 40),
              
              // 成功メッセージ
              Text(
                isStoreOwner ? "ポイントを送りました" : "支払いが完了しました",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: isStoreOwner ? Colors.green : const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 60),
              
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
                      size: 24,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Antenna Books & Cafe ココシバ",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                isStoreOwner ? "に付与" : "に支払い",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 50),
              
              // ポイント表示
              Text(
                isStoreOwner ? "お客様が獲得したポイント" : "送ったポイント",
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "250",
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "pt",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // 戻るボタン
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "戻る",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
} 