import 'package:flutter/material.dart';
import 'home_view.dart';
import 'map_view.dart';
import 'qr_code_views/qr_code_view.dart';
import 'post_view.dart';
import 'account_views/account_view.dart';

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  int selectedTab = 1;
  bool isShowCouponView = false;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // メインのタブビュー
            IndexedStack(
              index: selectedTab - 1,
              children: [
                HomeView(
                  selectedTab: selectedTab,
                  isShowCouponView: isShowCouponView,
                  onTabChanged: (tab) => setState(() => selectedTab = tab),
                  onCouponViewChanged: (show) => setState(() => isShowCouponView = show),
                ),
                const MapView(),
                const QRCodeView(),
                PostView(
                  isShowCouponView: isShowCouponView,
                  onCouponViewChanged: (show) => setState(() => isShowCouponView = show),
                ),
                const AccountView(),
              ],
            ),
            
            // 下部のタブバー
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        // ホームタブ
                        Expanded(
                          child: _buildTabItem(
                            icon: Icons.home,
                            label: 'ホーム',
                            isSelected: selectedTab == 1,
                            onTap: () {
                              setState(() => selectedTab = 1);
                              // ホームタブが選択された時にデータを再読み込み
                              _refreshCurrentTabData();
                            },
                          ),
                        ),
                        // マップタブ
                        Expanded(
                          child: _buildTabItem(
                            icon: Icons.map,
                            label: 'マップ',
                            isSelected: selectedTab == 2,
                            onTap: () {
                              setState(() => selectedTab = 2);
                              // マップタブが選択された時にデータを再読み込み
                              _refreshCurrentTabData();
                            },
                          ),
                        ),
                        // QRコードボタン（中央）
                        Expanded(
                          child: _buildQRCodeButton(),
                        ),
                        // 投稿タブ
                        Expanded(
                          child: _buildTabItem(
                            icon: Icons.grid_on,
                            label: '投稿',
                            isSelected: selectedTab == 4,
                            onTap: () {
                              setState(() => selectedTab = 4);
                              // 投稿タブが選択された時にデータを再読み込み
                              _refreshCurrentTabData();
                            },
                          ),
                        ),
                        // アカウントタブ
                        Expanded(
                          child: _buildTabItem(
                            icon: Icons.person,
                            label: 'アカウント',
                            isSelected: selectedTab == 5,
                            onTap: () {
                              setState(() => selectedTab = 5);
                              // アカウントタブが選択された時にデータを再読み込み
                              _refreshCurrentTabData();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF6B35) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF6B35) : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeButton() {
    return GestureDetector(
      onTap: () => setState(() => selectedTab = 3),
      child: Container(
        padding: const EdgeInsets.only(bottom: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code,
                    color: Colors.white,
                    size: 25,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'QRコード',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 現在のタブに応じてデータを再読み込み
  void _refreshCurrentTabData() {
    // 各タブのデータ再読み込みをトリガー
    // 実際のデータ再読み込みは各ビューのdidChangeDependenciesで処理される
    print('タブ ${selectedTab} のデータ再読み込みをトリガー');
  }
} 