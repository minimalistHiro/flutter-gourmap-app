import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_detail_view.dart';
import 'notification_settings_view.dart';

class NotificationListView extends StatefulWidget {
  const NotificationListView({super.key});

  @override
  State<NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<NotificationListView> {
  // Firebase関連
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // お知らせデータ
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  
  // 既読状態を管理
  Set<String> _readNotifications = {};
  
  // ユーザーのオーナー状態
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
    _loadNotifications();
    _loadReadStatus();
  }

  // ユーザーのオーナー状態を確認
  Future<void> _loadUserStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _isOwner = data['isOwner'] ?? false;
          });
        }
      }
    } catch (e) {
      print('ユーザー状態の読み込みに失敗しました: $e');
    }
  }

  // 既読状態を読み込む
  Future<void> _loadReadStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final readNotifications = List<String>.from(data['readNotifications'] ?? []);
          setState(() {
            _readNotifications = readNotifications.toSet();
          });
        }
      }
    } catch (e) {
      print('既読状態の読み込みに失敗しました: $e');
    }
  }

  // 既読状態を更新する
  Future<void> _markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'readNotifications': FieldValue.arrayUnion([notificationId]),
        });
        setState(() {
          _readNotifications.add(notificationId);
        });
      }
    } catch (e) {
      print('既読状態の更新に失敗しました: $e');
    }
  }

  // 既読状態をリセットする
  Future<void> _resetReadStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'readNotifications': [],
        });
        setState(() {
          _readNotifications.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('既読状態をリセットしました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('既読状態のリセットに失敗しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('既読状態のリセットに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // お知らせを読み込む
  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .get();
      
      // メモリ上でソート
      final List<Map<String, dynamic>> notifications = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // アクティブで公開済みのお知らせのみをフィルタリング
        final isActive = data['isActive'] ?? false;
        final isPublished = data['isPublished'] ?? false;
        final isOwnerOnly = data['isOwnerOnly'] ?? false;
        final type = data['type'] ?? 'notification';
        
        // オーナー専用通知の表示制御
        bool shouldShow = isActive && isPublished;
        if (isOwnerOnly && !_isOwner) {
          shouldShow = false;
        }
        
        if (shouldShow) {
          notifications.add({
            'id': doc.id,
            'title': data['title'] ?? 'タイトルなし',
            'content': data['content'] ?? '',
            'category': data['category'] ?? '一般',
            'priority': data['priority'] ?? '通常',
            'createdAt': data['createdAt'],
            'publishedAt': data['publishedAt'],
            'readCount': data['readCount'] ?? 0,
            'totalViews': data['totalViews'] ?? 0,
            'type': type,
            'isOwnerOnly': isOwnerOnly,
            'userId': data['userId'] ?? '',
            'username': data['username'] ?? '',
            'userEmail': data['userEmail'] ?? '',
          });
        }
      }
      
      // 作成日時でソート（新しい順）
      notifications.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      print('取得したお知らせ数: ${notifications.length}');
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });

    } catch (e) {
      print('お知らせデータの読み込みに失敗しました: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'お知らせ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isOwner) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'オーナー',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read, color: Colors.black),
            onPressed: _resetReadStatus,
            tooltip: '既読状態をリセット',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsView(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_notifications[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.announcement_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'お知らせがありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '新しいお知らせが投稿されるまでお待ちください',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = _readNotifications.contains(notification['id']);
    
    return GestureDetector(
      onTap: () {
        // 既読状態を更新
        _markAsRead(notification['id']);
        
        // 通知詳細画面への遷移
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NotificationDetailView(notificationId: notification['id']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isRead ? Border.all(color: Colors.grey[300]!) : null,
          boxShadow: isRead ? null : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // プロフィール画像（既読状態を示す）
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: notification['type'] == 'feedback' 
                        ? const Color(0xFFFF6B35).withOpacity(0.1)
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                    border: notification['type'] == 'feedback'
                        ? Border.all(color: const Color(0xFFFF6B35), width: 2)
                        : null,
                  ),
                  child: Icon(
                    notification['type'] == 'feedback' 
                        ? Icons.feedback
                        : Icons.notifications,
                    color: notification['type'] == 'feedback'
                        ? const Color(0xFFFF6B35)
                        : Colors.grey,
                    size: 24,
                  ),
                ),
                if (!isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // 通知内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(notification['priority']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getPriorityColor(notification['priority']).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          notification['priority'],
                          style: TextStyle(
                            fontSize: 10,
                            color: _getPriorityColor(notification['priority']),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // フィードバックの場合は送信者情報を表示
                  if (notification['type'] == 'feedback') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '送信者: ${notification['username']} (${notification['userEmail']})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    notification['content'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    maxLines: notification['type'] == 'feedback' ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notification['category'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (notification['createdAt'] != null) ...[
                        Text(
                          _formatDate(notification['createdAt']),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case '低':
        return Colors.grey;
      case '通常':
        return Colors.blue;
      case '高':
        return Colors.orange;
      case '緊急':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今日';
    } else if (difference.inDays == 1) {
      return '昨日';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
} 