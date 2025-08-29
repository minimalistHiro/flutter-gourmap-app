import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../../services/referral_service.dart';

class EmailSignUpView extends StatefulWidget {
  const EmailSignUpView({super.key});

  @override
  State<EmailSignUpView> createState() => _EmailSignUpViewState();
}

class _EmailSignUpViewState extends State<EmailSignUpView> {
  bool isShowPassword = false;
  bool isShowPassword2 = false;
  bool isAgree = false;
  bool isOpenTermsOfServiceView = false;
  bool isLoading = false;
  
  String email = '';
  String password = '';
  String password2 = '';
  String username = '';
  String age = '';
  String address = '';
  String gender = ''; // 性別を追加
  String referralCode = ''; // 紹介コードを追加
  bool _isValidatingReferralCode = false;
  String? _referralCodeValidationMessage;
  
  // 画像関連の状態変数
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  bool _isImageLoading = false;
  
  // TextEditingControllerを適切に管理
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _password2Controller;
  late TextEditingController _usernameController;
  late TextEditingController _referralCodeController;
  
  // ImagePicker
  final ImagePicker _picker = ImagePicker();
  
  // ReferralService
  final ReferralService _referralService = ReferralService();
  
  final List<String> ages = [
    '10代', '20代', '30代', '40代', '50代', '60代', '70代以上'
  ];
  
  final List<String> addresses = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
    '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
    '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
    '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
  ];

  // LGBTQに配慮した性別選択肢
  final List<String> genders = [
    '男性',
    '女性',
    'その他',
    '回答しない'
  ];

  bool get disabled {
    return email.isEmpty || password.isEmpty || password2.isEmpty || username.isEmpty || !isAgree;
  }

  @override
  void initState() {
    super.initState();
    // TextEditingControllerを初期化
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _password2Controller = TextEditingController();
    _usernameController = TextEditingController();
    _referralCodeController = TextEditingController();
  }

  @override
  void dispose() {
    // TextEditingControllerを適切に破棄
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _usernameController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  // 紹介コードをリアルタイムで検証
  Future<void> _validateReferralCode(String code) async {
    if (code.trim().isEmpty) {
      setState(() {
        _referralCodeValidationMessage = null;
        _isValidatingReferralCode = false;
      });
      return;
    }

    setState(() {
      _isValidatingReferralCode = true;
      _referralCodeValidationMessage = null;
    });

    try {
      // 500ms待機してAPIコールを制限
      await Future.delayed(const Duration(milliseconds: 500));
      
      // まだ同じコードが入力されているかチェック
      if (code.trim() != referralCode.trim()) {
        return; // ユーザーが入力を変更した場合は検証をキャンセル
      }

      final result = await _referralService.validateReferralCode(code.trim());
      
      if (mounted && code.trim() == referralCode.trim()) {
        setState(() {
          _isValidatingReferralCode = false;
          if (result != null) {
            _referralCodeValidationMessage = '✓ ${result['username']}さんの紹介コードです';
          } else {
            _referralCodeValidationMessage = '✗ 無効な紹介コードです';
          }
        });
      }
    } catch (e) {
      if (mounted && code.trim() == referralCode.trim()) {
        setState(() {
          _isValidatingReferralCode = false;
          _referralCodeValidationMessage = '✗ 検証に失敗しました';
        });
      }
    }
  }

  // 画像選択メソッド
  Future<void> _pickImage() async {
    try {
      setState(() {
        _isImageLoading = true;
      });

      print('画像選択開始...');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        print('画像ファイル選択完了: ${pickedFile.name}');
        
        if (kIsWeb) {
          // Webプラットフォームの場合
          print('Webプラットフォームでの画像処理開始...');
          final bytes = await pickedFile.readAsBytes();
          print('Web画像選択: ${bytes.length} bytes');
          
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageFile = null;

          });
          
          print('Web画像設定完了: _selectedImageBytes = ${_selectedImageBytes?.length} bytes');
        } else {
          // モバイルプラットフォームの場合
          print('モバイルプラットフォームでの画像処理開始...');
          final file = File(pickedFile.path);
          final bytes = await file.readAsBytes();
          print('モバイル画像選択: ${bytes.length} bytes');
          
          setState(() {
            _selectedImageFile = file;
            _selectedImageBytes = bytes;

          });
          
          print('モバイル画像設定完了: _selectedImageBytes = ${_selectedImageBytes?.length} bytes');
        }
        
        print('画像選択完了: _selectedImageBytes = ${_selectedImageBytes?.length} bytes');
        print('_selectedImageFile = ${_selectedImageFile?.path}');
      } else {
        print('画像が選択されませんでした');
      }
    } catch (e) {
      print('画像選択エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像選択に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  // 画像をFirebase Storageにアップロード
  Future<String> _uploadProfileImage() async {
    if (_selectedImageBytes == null) {
      throw Exception('画像が選択されていません。');
    }

    try {
      print('Firebase Storage アップロード開始...');
      print('画像サイズ: ${_selectedImageBytes!.length} bytes');
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      print('Storage参照作成: ${ref.fullPath}');
      
      // 画像データをアップロード
      final uploadTask = ref.putData(_selectedImageBytes!);
      print('アップロードタスク開始...');
      
      // アップロード完了を待機
      final snapshot = await uploadTask;
      print('アップロード完了: ${snapshot.bytesTransferred} bytes');
      
      // ダウンロードURLを取得
      final downloadUrl = await ref.getDownloadURL();
      print('ダウンロードURL取得: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('画像アップロードエラー詳細: $e');
      print('エラータイプ: ${e.runtimeType}');
      
      if (e.toString().contains('permission-denied') || e.toString().contains('unauthorized')) {
        throw Exception('Firebase Storageへのアクセス権限がありません。管理者にお問い合わせください。');
      } else if (e.toString().contains('network')) {
        throw Exception('ネットワークエラーが発生しました。インターネット接続を確認してください。');
      } else {
        throw Exception('画像のアップロードに失敗しました: $e');
      }
    }
  }

  // アカウント作成処理
  Future<void> _createAccount() async {
    if (password != password2) {
      _showErrorDialog('パスワード不一致', 'パスワードとパスワード（確認）が一致しません。\n同じパスワードを入力してください。');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print('=== アカウント作成開始 ===');
      print('Email: $email');
      print('Username: $username');
      print('Age: $age');
      print('Address: $address');
      print('Gender: $gender'); // 性別も出力
      
      // 画像をFirebase Storageに保存
      String profileImageUrl = '';
      print('画像処理開始: _selectedImageBytes = ${_selectedImageBytes?.length} bytes');
      
      if (_selectedImageBytes != null && _selectedImageBytes!.isNotEmpty) {
        try {
          print('画像アップロード開始: 画像サイズ = ${_selectedImageBytes!.length} bytes');
          profileImageUrl = await _uploadProfileImage();
          print('プロフィール画像のアップロード成功: $profileImageUrl');
        } catch (e) {
          print('プロフィール画像のアップロードに失敗: $e');
          // 画像アップロードに失敗してもアカウント作成は続行
          profileImageUrl = '';
        }
      } else {
        print('画像が選択されていないか、空です');
        print('_selectedImageBytes: ${_selectedImageBytes?.length ?? 'null'} bytes');
      }
      
      print('最終的なprofileImageUrl: $profileImageUrl');
      
      // Firebase認証でアカウント作成
      print('Firebase Auth アカウント作成開始...');
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      
      print('Firebase Auth アカウント作成成功: ${userCredential.user?.uid}');

      final User? user = userCredential.user;
      if (user != null) {
        // Firestoreにユーザー情報を保存
        print('Firestore ユーザー情報保存開始...');
        
        try {
          print('Firestore保存開始 - profileImageUrl: $profileImageUrl');
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': email,
            'username': username,
            'age': age,
            'address': address,
            'gender': gender, // 性別を追加
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'profileImageUrl': profileImageUrl, // アップロードした画像のURL
            'points': 0, // 初期ポイント
            'isActive': true, // アカウントの有効状態
            'lastLoginAt': FieldValue.serverTimestamp(), // 最終ログイン時刻
            'isStoreOwner': false, // 店舗アカウントか否かのステータス
            'goldStamps': 0, // ゴールドスタンプ数
            'paid': 0, // 総支払額
            'readNotifications': [], // 既読通知リスト
            'accountType': 'email', // アカウント作成方法
            'isOwner': false, // オーナーフラグ
          });
          
          print('Firestore ユーザー情報保存成功 - profileImageUrl: $profileImageUrl');
          
          // 紹介コード処理
          if (referralCode.trim().isNotEmpty) {
            try {
              print('紹介コード処理開始: $referralCode');
              await _referralService.processReferral(user.uid, referralCode.trim());
              print('紹介コード処理成功');
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('紹介コードが適用され、1000ポイントを獲得しました！'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } catch (referralError) {
              print('紹介コード処理エラー: $referralError');
              // 紹介エラーは致命的ではないので、警告メッセージのみ
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('紹介コードの処理に失敗しました: $referralError'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }
          }

          // 成功メッセージ
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('アカウントを作成しました'),
                backgroundColor: Colors.green,
              ),
            );
            
            // アカウント作成完了後、content_view.dartに画面遷移
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        } on FirebaseException catch (firestoreError) {
          print('=== Firestore エラー発生 ===');
          print('Error Code: ${firestoreError.code}');
          print('Error Message: ${firestoreError.message}');
          
          String errorTitle = 'データベース保存エラー';
          String errorMessage = 'ユーザー情報の保存に失敗しました。';
          
          switch (firestoreError.code) {
            case 'permission-denied':
              errorTitle = '権限が不足しています';
              errorMessage = 'データベースへの書き込み権限がありません。\n\n対処方法：\n• 管理者にお問い合わせください\n• しばらく時間をおいてから再度お試しください';
              break;
            case 'unavailable':
              errorTitle = 'データベースが利用できません';
              errorMessage = 'データベースサービスが一時的に利用できません。\n\nしばらく時間をおいてから再度お試しください。';
              break;
            case 'resource-exhausted':
              errorTitle = 'リソースが不足しています';
              errorMessage = 'データベースのリソースが不足しています。\n\nしばらく時間をおいてから再度お試しください。';
              break;
            default:
              errorMessage = 'データベース保存中にエラーが発生しました。\n\nエラーコード: ${firestoreError.code}\nエラーメッセージ: ${firestoreError.message}\n\nしばらく時間をおいてから再度お試しください。';
          }
          
          if (mounted) {
            _showErrorDialog(errorTitle, errorMessage);
          }
          
          // Firestore保存に失敗した場合、作成したユーザーアカウントを削除
          try {
            await user.delete();
            print('Firebase Auth ユーザーアカウントを削除しました');
          } catch (deleteError) {
            print('ユーザーアカウントの削除に失敗: $deleteError');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      print('=== FirebaseAuthException 発生 ===');
      print('Error Code: ${e.code}');
      print('Error Message: ${e.message}');
      print('Error Details: ${e.toString()}');
      
      String errorTitle = 'アカウント作成エラー';
      String errorMessage = 'アカウント作成に失敗しました。';
      
      switch (e.code) {
        case 'weak-password':
          errorTitle = 'パスワードが弱すぎます';
          errorMessage = 'パスワードは最低6文字以上で、英数字を含む複雑なパスワードを設定してください。\n\n推奨：\n• 8文字以上\n• 大文字・小文字・数字・記号を含む\n• 個人情報を含まない';
          break;
        case 'email-already-in-use':
          errorTitle = 'メールアドレスが既に使用されています';
          errorMessage = 'このメールアドレスは既に別のアカウントで使用されています。\n\n対処方法：\n• 別のメールアドレスを使用する\n• 既存のアカウントにログインする\n• パスワードをリセットする';
          break;
        case 'invalid-email':
          errorTitle = '無効なメールアドレスです';
          errorMessage = '入力されたメールアドレスの形式が正しくありません。\n\n正しい形式：\n• example@domain.com\n• user.name@company.co.jp\n\n確認事項：\n• @マークが含まれているか\n• ドメイン部分が正しいか\n• スペースや特殊文字が含まれていないか';
          break;
        case 'operation-not-allowed':
          errorTitle = 'メール・パスワード認証が無効です';
          errorMessage = 'このアプリではメール・パスワードによる認証が設定されていません。\n\n開発者にお問い合わせください。';
          break;
        case 'too-many-requests':
          errorTitle = 'リクエストが多すぎます';
          errorMessage = '短時間に多くのリクエストが送信されました。\n\nしばらく時間をおいてから再度お試しください。';
          break;
        default:
          errorTitle = '認証エラー';
          errorMessage = 'アカウント作成中にエラーが発生しました。\n\nエラーコード: ${e.code}\nエラーメッセージ: ${e.message}\n\nしばらく時間をおいてから再度お試しください。';
      }
      
      if (mounted) {
        _showErrorDialog(errorTitle, errorMessage);
      }
    } catch (e) {
      print('=== 予期しないエラー発生 ===');
      print('Error: $e');
      print('Error Type: ${e.runtimeType}');
      
      if (mounted) {
        _showErrorDialog(
          '予期しないエラー',
          'アカウント作成中に予期しないエラーが発生しました。\n\nエラー詳細: $e\n\nしばらく時間をおいてから再度お試しください。\n問題が解決しない場合は、開発者にお問い合わせください。'
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 利用規約ダイアログを表示
  void _showTermsOfServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '利用規約',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'GourMap 利用規約',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '第1条（適用）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '本規約は、GourMapアプリケーション（以下「本アプリ」）の利用に関して適用されます。',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 8),
                Text(
                  '第2条（利用登録）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '本アプリの利用を希望する者は、本規約に同意の上、本アプリの定める方法によって利用登録を行うものとします。',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 8),
                Text(
                  '第3条（禁止事項）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '利用者は、本アプリの利用にあたり、以下の行為をしてはなりません。\n'
                  '• 法令または公序良俗に違反する行為\n'
                  '• 犯罪行為に関連する行為\n'
                  '• 他の利用者に迷惑をかける行為\n'
                  '• 本アプリの運営を妨害する行為',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 8),
                Text(
                  '第4条（本アプリの提供の停止等）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '本アプリは、利用者に事前に通知することなく、本アプリの全部または一部の提供を停止または中断することができるものとします。',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 8),
                Text(
                  '第5条（免責事項）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '本アプリは、本アプリに関して、利用者と他の利用者または第三者との間において生じた取引、連絡または紛争等について一切責任を負いません。',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 8),
                Text(
                  '第6条（規約の変更）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '本アプリは、必要と判断した場合には、利用者に通知することなくいつでも本規約を変更することができるものとします。',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 8),
                Text(
                  '第7条（準拠法・裁判管轄）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '本規約の解釈にあたっては、日本法を準拠法とします。\n'
                  '本規約に関して紛争が生じた場合には、東京地方裁判所を第一審の専属的合意管轄裁判所とします。',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 16),
                Text(
                  '以上',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '2024年8月22日 制定',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 利用規約を表示した後、同意チェックボックスを有効にする
                setState(() {
                  isOpenTermsOfServiceView = true;
                });
              },
              child: const Text(
                '閉じる',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
  }

  // エラーダイアログを表示
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.blue,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'メールアドレスで登録',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // ユーザー名
            _buildTextField(
              label: 'ユーザー名',
              hint: 'ストコポ太郎',
              controller: _usernameController,
              onChanged: (value) => setState(() => username = value),
            ),
            
            const SizedBox(height: 20),
            
            // 年代選択
            _buildDropdownField(
              label: '年代',
              hint: '年代を選択してください。',
              value: age,
              items: ages,
              onChanged: (value) => setState(() => age = value ?? ''),
            ),
            
            const SizedBox(height: 20),
            
            // 住所選択
            _buildDropdownField(
              label: '住所',
              hint: '住所を選択してください。',
              value: address,
              items: addresses,
              onChanged: (value) => setState(() => address = value ?? ''),
            ),
            
            const SizedBox(height: 20),
            
            // 性別選択
            _buildDropdownField(
              label: '性別',
              hint: '性別を選択してください。',
              value: gender,
              items: genders,
              onChanged: (value) => setState(() => gender = value ?? ''),
            ),
            
            const SizedBox(height: 20),
            
            // 紹介コード（任意）
            _buildReferralCodeField(),
            
            const SizedBox(height: 20),
            
            // プロフィール画像
            const Text(
              'プロフィール画像（任意）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 10),
            
            GestureDetector(
              onTap: _isImageLoading ? null : _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedImageBytes != null ? Colors.blue : Colors.grey,
                    width: _selectedImageBytes != null ? 2 : 1,
                  ),
                ),
                child: _isImageLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    : _selectedImageBytes != null
                        ? ClipOval(
                            child: Image.memory(
                              _selectedImageBytes!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 50,
                          ),
              ),
            ),
            
            if (_selectedImageBytes != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImageFile = null;
                    _selectedImageBytes = null;
        
                  });
                },
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('画像を削除'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
            
            const SizedBox(height: 30),
            
            // メールアドレス
            _buildTextField(
              label: 'メールアドレス',
              hint: 'gourmap@example.com',
              controller: _emailController,
              onChanged: (value) => setState(() => email = value),
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 30),
            
            // パスワード
            _buildPasswordField(
              label: 'パスワード',
              controller: _passwordController,
              onChanged: (value) => setState(() => password = value),
              isShowPassword: isShowPassword,
              onTogglePassword: () => setState(() => isShowPassword = !isShowPassword),
            ),
            
            const SizedBox(height: 20),
            
            // パスワード確認
            _buildPasswordField(
              label: 'パスワード（確認）',
              controller: _password2Controller,
              onChanged: (value) => setState(() => password2 = value),
              isShowPassword: isShowPassword2,
              onTogglePassword: () => setState(() => isShowPassword2 = !isShowPassword2),
            ),
            
            const SizedBox(height: 30),
            
            // 利用規約ボタン
            GestureDetector(
              onTap: () {
                _showTermsOfServiceDialog();
              },
              child: const Text(
                '利用規約を表示',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // 同意チェックボックス
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (isOpenTermsOfServiceView) {
                      setState(() => isAgree = !isAgree);
                    }
                  },
                  child: Icon(
                    isAgree ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isOpenTermsOfServiceView ? Colors.blue : Colors.grey,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  '利用規約に同意します',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 50),
            
            // アカウント作成ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (disabled || isLoading) ? null : _createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (disabled || isLoading) ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'アカウントを作成',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    int? maxLength,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: isOptional 
                ? const Icon(Icons.info_outline, size: 16, color: Colors.grey)
                : null,
            helperText: isOptional 
                ? '双方に1000ポイント獲得のチャンス！' 
                : null,
            helperStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFF6B35),
            ),
            counterText: maxLength != null ? '' : null, // 文字数カウンターを非表示
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    required bool isShowPassword,
    required VoidCallback onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: !isShowPassword,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                isShowPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: onTogglePassword,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReferralCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '友達紹介コード（任意）',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _referralCodeController,
          onChanged: (value) {
            setState(() => referralCode = value);
            _validateReferralCode(value);
          },
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: '友達から教えてもらったコードを入力',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF6B35)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: _isValidatingReferralCode
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  )
                : _referralCodeValidationMessage != null
                    ? Icon(
                        _referralCodeValidationMessage!.startsWith('✓')
                            ? Icons.check_circle
                            : Icons.error,
                        color: _referralCodeValidationMessage!.startsWith('✓')
                            ? Colors.green
                            : Colors.red,
                      )
                    : const Icon(Icons.info_outline, size: 16, color: Colors.grey),
            helperText: _referralCodeValidationMessage ?? '双方に1000ポイント獲得のチャンス！',
            helperStyle: TextStyle(
              fontSize: 12,
              color: _referralCodeValidationMessage != null
                  ? (_referralCodeValidationMessage!.startsWith('✓')
                      ? Colors.green
                      : Colors.red)
                  : const Color(0xFFFF6B35),
            ),
            counterText: '', // 文字数カウンターを非表示
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
} 