import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileEditView extends StatefulWidget {
  const ProfileEditView({super.key});

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  final TextEditingController _bioController = TextEditingController();
  
  bool _isLoading = false;
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  String? _currentBio;
  String? _currentProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  // 現在のデータを読み込み
  Future<void> _loadCurrentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final bio = userData['bio'] ?? '';
          final profileImageUrl = userData['profileImageUrl'] ?? '';
          setState(() {
            _currentBio = bio;
            _currentProfileImageUrl = profileImageUrl;
            _bioController.text = bio;
          });
        }
      }
    } catch (e) {
      print('データの読み込みに失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'プロフィール編集',
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
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // プロフィール画像セクション
            _buildProfileImageSection(),
            
            const SizedBox(height: 30),
            
            // プロフィール情報セクション
            _buildProfileInfoSection(),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // プロフィール画像
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: _selectedImage != null
                    ? ClipOval(
                        child: kIsWeb && _selectedImageBytes != null
                            ? Image.memory(
                                _selectedImageBytes!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : _selectedImage != null
                                ? Image.file(
                                    _selectedImage!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 60,
                                  ),
                      )
                    : _currentProfileImageUrl?.isNotEmpty == true
                         ? ClipOval(
                             child: Image.network(
                               _currentProfileImageUrl!,
                               width: 120,
                               height: 120,
                               fit: BoxFit.cover,
                               errorBuilder: (context, error, stackTrace) {
                                 return const Icon(
                                   Icons.person,
                                   color: Colors.grey,
                                   size: 60,
                                 );
                               },
                             ),
                           )
                         : const Icon(
                             Icons.person,
                             color: Colors.grey,
                             size: 60,
                           ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 画像変更ボタン
          TextButton(
            onPressed: _changeProfileImage,
            child: const Text(
              'プロフィール画像を変更',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // 自己紹介
          _buildTextField(
            controller: _bioController,
            label: '自己紹介',
            icon: Icons.description,
            hint: '自己紹介を入力してください',
            maxLines: 3,
            maxLength: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
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
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey[200],
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  void _changeProfileImage() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'プロフィール画像を選択',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('カメラで撮影'),
              onTap: () async {
                Navigator.of(context).pop();
                await _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('フォトライブラリから選択'),
              onTap: () async {
                Navigator.of(context).pop();
                await _pickImageFromGallery();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // カメラで撮影
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (photo != null) {
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = File(photo.path);
            _selectedImageBytes = null;
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('写真を撮影しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カメラで撮影できませんでした: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // フォトライブラリから選択
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = File(image.path);
            _selectedImageBytes = null;
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('画像を選択しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像を選択できませんでした: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ユーザーが見つかりませんでした。'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final bio = _bioController.text;

      if (bio.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('自己紹介を入力してください。'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      if (_selectedImage != null || _selectedImageBytes != null) {
        try {
          // 画像をFirebase Storageにアップロード
          String? imageUrl;
          if (kIsWeb && _selectedImageBytes != null) {
            final ref = FirebaseStorage.instance
                .ref()
                .child('profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
            await ref.putData(_selectedImageBytes!);
            imageUrl = await ref.getDownloadURL();
          } else if (_selectedImage != null) {
            final bytes = await _selectedImage!.readAsBytes();
            final ref = FirebaseStorage.instance
                .ref()
                .child('profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
            await ref.putData(bytes);
            imageUrl = await ref.getDownloadURL();
          }

          // 画像URLをデータベースに保存
          if (imageUrl != null) {
            await userRef.update({
              'bio': bio,
              'profileImageUrl': imageUrl,
            });
            print('画像と自己紹介を更新しました: $imageUrl');
          } else {
            await userRef.update({
              'bio': bio,
            });
            print('自己紹介のみ更新しました');
          }
        } catch (e) {
          print('画像アップロードに失敗: $e');
          // 画像アップロードに失敗しても自己紹介は保存
          await userRef.update({
            'bio': bio,
          });
          print('画像アップロード失敗、自己紹介のみ更新しました');
        }
      } else {
        // 画像が選択されていない場合は自己紹介のみ保存
        await userRef.update({
          'bio': bio,
        });
        print('自己紹介のみ更新しました');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました。'),
            backgroundColor: Colors.green,
          ),
        );
        
        // アカウント画面に戻り、データを再読み込みするように結果を返す
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('プロフィールの更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 