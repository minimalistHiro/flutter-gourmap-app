import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'get_point_view.dart';
import 'send_point_view.dart';

class QRCodeView extends StatefulWidget {
  const QRCodeView({super.key});

  @override
  State<QRCodeView> createState() => _QRCodeViewState();
}

class _QRCodeViewState extends State<QRCodeView> with TickerProviderStateMixin {
  int selectedTab = 0; // 0: QRコード, 1: カメラ
  bool isSendPay = false;
  bool isShowGetPointView = false;
  bool isShowSendPointView = false;
  double brightness = 0.5; // デフォルト輝度
  
  // ユーザーデータ
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _currentUserId;
  String? _qrToken;
  int? _tokenExpiresAt;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // 画面輝度を最大に設定
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    // 画面輝度を元に戻す
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  // ユーザーデータを読み込み
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        
        // Firestoreからユーザーデータを取得
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && mounted) {
          setState(() {
            _userData = userDoc.data()!;
          });
        }
        
        // JWTトークンを取得
        if (mounted) {
          await _issueUserQr();
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ユーザーデータの読み込みに失敗: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // JWTトークンを発行
  Future<void> _issueUserQr() async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('issueUserQr');
      
      final result = await callable.call();
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true && mounted) {
        setState(() {
          _qrToken = data['qrToken'];
          _tokenExpiresAt = data['expiresAt'];
          _isLoading = false;
        });
        
        print('JWTトークン発行成功: ${_qrToken}');
        print('有効期限: ${_tokenExpiresAt}');
      } else {
        print('JWTトークン発行失敗: ${data['error']}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('JWTトークン発行エラー: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'QRコード',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // メインコンテンツ
                Expanded(
                  flex: 3,
                  child: _buildMainContent(),
                ),
                
                // タブバー
                Expanded(
                  flex: 1,
                  child: _buildTabBar(),
                ),
                
                // 下部の余白を追加
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildMainContent() {
    switch (selectedTab) {
      case 0:
        return _buildQRCodeTab();
      case 1:
        return _buildCameraTab();
      default:
        return _buildQRCodeTab();
    }
  }

  Widget _buildQRCodeTab() {
    final username = _userData?['username'] ?? 'ユーザー名未設定';
    final points = _userData?['points'] ?? 0;
    final profileImageUrl = _userData?['profileImageUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ユーザー情報
            Row(
              children: [
                const Spacer(),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5),
                    shape: BoxShape.circle,
                  ),
                  child: profileImageUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            profileImageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 10),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 20),
            
            // QRコード
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SendPointView(
                      isStoreOwner: true,
                      onSendPayChanged: (isSendPay) {
                        setState(() {
                          this.isSendPay = isSendPay;
                        });
                      },
                    ),
                  ),
                );
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Stack(
                  children: [
                    // QRコード
                    if (_qrToken != null)
                      Center(
                        child: QrImageView(
                          data: _qrToken!,
                          version: QrVersions.auto,
                          size: 160,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    // ロゴオーバーレイ
                    Positioned(
                      top: 75,
                      left: 75,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Icon(
                          Icons.store,
                          size: 20,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // JWTトークン情報表示
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'JWTトークン（60秒TTL）:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _qrToken ?? 'JWT未設定',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_tokenExpiresAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '有効期限: ${DateTime.fromMillisecondsSinceEpoch(_tokenExpiresAt!).toLocal().toString().substring(11, 19)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 15),
            
            // ポイント情報
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // ポイント獲得画面に遷移
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GetPointView(
                          onGetPointViewChanged: (show) {
                            // ポイント獲得画面の表示状態を管理
                          },
                          onTabChanged: (tab) {
                            // タブ変更時の処理
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    '保有ポイント',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$points',
                  style: const TextStyle(
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
              ],
            ),
            
            const SizedBox(height: 10), // 空白を小さく
          ],
        ),
      ),
    );
  }

  Widget _buildCameraTab() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // カメラプレビュー（プレースホルダー）
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'QRコードをスキャン',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'カメラでQRコードを読み取ります',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // スキャン枠
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // スキャンアニメーション
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              icon: Icons.qr_code,
              text: 'QRコード',
              isSelected: selectedTab == 0,
              onTap: () {
                setState(() {
                  selectedTab = 0;
                });
                // 画面輝度を最大に設定
                SystemChrome.setSystemUIOverlayStyle(
                  const SystemUiOverlayStyle(
                    statusBarBrightness: Brightness.light,
                  ),
                );
              },
            ),
          ),
          Container(
            width: 2,
            height: 50,
            color: Colors.black.withOpacity(0.4),
          ),
          Expanded(
            child: _buildTabButton(
              icon: Icons.qr_code_scanner,
              text: 'カメラでスキャン',
              isSelected: selectedTab == 1,
              onTap: () {
                setState(() {
                  selectedTab = 1;
                });
                // 画面輝度を元に戻す
                SystemChrome.setSystemUIOverlayStyle(
                  const SystemUiOverlayStyle(
                    statusBarBrightness: Brightness.dark,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
              color: isSelected 
                ? const Color(0xFF1E88E5) 
                : Colors.black.withOpacity(0.3),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                  ? const Color(0xFF1E88E5) 
                  : Colors.black.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // QRコード読み取り処理
  void handleScan(String result) {
    print('QR Code scanned: $result');
    // スキャン成功時の処理
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('QRコードを読み取りました: $result')),
    );
  }
} 