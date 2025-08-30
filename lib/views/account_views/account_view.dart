import 'package:flutter/material.dart';
import '../../services/firebase_auth_service.dart';
import 'profile_edit_view.dart';
import 'update_username_view.dart';

import '../notification_list_view.dart';
import 'privacy_settings_view.dart';
import 'language_settings_view.dart';
import 'help_view.dart';
import 'contact_view.dart';
import 'terms_view.dart';
import 'privacy_policy_view.dart';
import 'change_password_view.dart';
import 'create_store_view.dart';
import 'my_store_list_view.dart';
import 'create_notification_view.dart';
import 'create_post_view.dart';
import 'create_coupon_view.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面が表示されるたびにデータを再読み込み
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    // 退会確認ダイアログを表示
    final bool? shouldDeleteAccount = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'アカウント退会確認',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '本当にアカウントを削除しますか？\n\nこの操作は取り消すことができません。\n\n・すべてのデータが削除されます\n・投稿、ポイント、スタンプが失われます\n・店舗情報も削除されます',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'キャンセル',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                '退会する',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );

    // ユーザーが退会を確認した場合のみ実行
    if (shouldDeleteAccount == true) {
      try {
        // Firebase Authからアカウントを削除
        final user = _authService.currentUser;
        if (user != null) {
          await user.delete();
          // 退会後はwelcome_view.dartに戻る
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/welcome',
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('アカウント退会に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _signOut() async {
    // ログアウト確認ダイアログを表示
    final bool? shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'ログアウト確認',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '本当にログアウトしますか？\n\nログアウトすると、アプリの機能が制限されます。',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'キャンセル',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'ログアウト',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );

    // ユーザーがログアウトを確認した場合のみ実行
    if (shouldSignOut == true) {
      try {
        await _authService.signOut();
        // ログアウト後にwelcome_view.dartに戻る
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/welcome',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ログアウトに失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'アカウント',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // プロフィールセクション
                  _buildProfileSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 設定メニュー
                  _buildSettingsMenu(),
                  
                  const SizedBox(height: 20),
                  
                  // ログアウトボタン
                  _buildLogoutButton(),
                  
                  const SizedBox(height: 16),
                  
                  // 退会ボタン
                  _buildDeleteAccountButton(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection() {
    final username = _userData?['username'] ?? 'ユーザー名未設定';
    final email = _userData?['email'] ?? 'メールアドレス未設定';
    final points = _userData?['points'] ?? 0;
                    final goldStamps = _userData?['goldStamps'] ?? 0;
    final rank = _userData?['rank'] ?? 'ブロンズ';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // プロフィール情報
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // アバター
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: _userData?['profileImageUrl']?.isNotEmpty == true
                      ? ClipOval(
                          child: Image.network(
                            _userData!['profileImageUrl'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: const Color(0xFF1E88E5),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: const Color(0xFF1E88E5),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                ),
                
                const SizedBox(width: 20),
                
                // ユーザー情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          rank,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      // 自己紹介を追加
                      if (_userData?['bio']?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '自己紹介',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userData!['bio'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 編集ボタン
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfileEditView(),
                      ),
                    );
                    
                    // プロフィールが更新された場合はデータを再読み込み
                    if (result == true) {
                      _loadUserData();
                    }
                  },
                  icon: const Icon(Icons.edit, color: Colors.blue),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // ポイント・スタンプ情報
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.monetization_on,
                    title: 'ポイント',
                    value: '$points pt',
                    color: Colors.orange,
                    imagePath: 'assets/images/point_icon.png',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.star,
                    title: 'ゴールドスタンプ',
                    value: '$goldStamps 個',
                    color: Colors.amber,
                    imagePath: 'assets/images/gold_coin_icon2.png',
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          imagePath != null
              ? ClipOval(
                  child: Image.asset(
                    imagePath,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(icon, color: color, size: 24);
                    },
                  ),
                )
              : Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
                     _buildMenuItem(
             icon: Icons.person,
             title: 'ユーザー名を変更',
             onTap: () {
               Navigator.of(context).push(
                 MaterialPageRoute(
                   builder: (context) => const UpdateUsernameView(username: ''),
                 ),
               );
             },
           ),

          _buildMenuItem(
            icon: Icons.lock,
            title: 'パスワードを変更',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordView(),
                ),
              );
            },
          ),
                     _buildMenuItem(
             icon: Icons.notifications,
             title: '通知設定',
             onTap: () {
               Navigator.of(context).push(
                 MaterialPageRoute(
                   builder: (context) => const NotificationListView(),
                 ),
               );
             },
           ),
          _buildMenuItem(
            icon: Icons.privacy_tip,
            title: 'プライバシー設定',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: '言語設定',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LanguageSettingsView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help,
            title: 'ヘルプ',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HelpView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.contact_support,
            title: 'お問い合わせ',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ContactView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.description,
            title: '利用規約',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TermsView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'プライバシーポリシー',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.store,
            title: '新規店舗作成',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateStoreView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.edit_location,
            title: '店舗情報変更',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyStoreListView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.announcement,
            title: '新規お知らせ作成',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateNotificationView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.post_add,
            title: '新規投稿作成',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreatePostView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.local_offer,
            title: '新規クーポン作成',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateCouponView(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _signOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'ログアウト',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _showDeleteAccountDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[700],
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'アカウント退会',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 