import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show Point;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'menu_management_view.dart';

class CreateStoreView extends StatefulWidget {
  const CreateStoreView({super.key});

  @override
  State<CreateStoreView> createState() => _CreateStoreViewState();
}

class _CreateStoreViewState extends State<CreateStoreView> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _xController = TextEditingController();
  final _facebookController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  String _selectedCategory = 'カフェ';
  bool _isLoading = false;
  
  // 営業時間のコントローラー
  final Map<String, Map<String, TextEditingController>> _businessHoursControllers = {};
  final Map<String, bool> _businessDaysOpen = {};
  
  // タグのコントローラー
  final _tagsController = TextEditingController();
  List<String> _tags = [];
  
  // 店舗アイコン画像の状態
  File? _selectedIconImage;
  String? _iconImageUrl;
  bool _isUploadingIcon = false;
  
  // 店舗イメージ画像の状態
  File? _selectedStoreImage;
  String? _storeImageUrl;
  bool _isUploadingStoreImage = false;
  
  // 位置情報の状態
  LatLng? _selectedLocation;
  bool _showMap = false;

  final List<String> _categories = [
    'カフェ',
    'レストラン',
    '居酒屋',
    'ファストフード',
    'スイーツ',
    'その他',
  ];

  @override
  void initState() {
    super.initState();
    _initializeBusinessHoursControllers();
    _initializeLocationControllers();
  }

  void _initializeBusinessHoursControllers() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (String day in days) {
      _businessHoursControllers[day] = {
        'open': TextEditingController(text: '09:00'),
        'close': TextEditingController(text: '18:00'),
      };
      _businessDaysOpen[day] = true;
    }
    _businessDaysOpen['sunday'] = false; // 日曜日はデフォルトで閉店
  }

  void _initializeLocationControllers() {
    _selectedLocation = const LatLng(35.6581, 139.7017); // 東京のデフォルト位置
    _updateLocationControllers();
  }
  
  void _updateLocationControllers() {
    if (_selectedLocation != null) {
      _latitudeController.text = _selectedLocation!.latitude.toStringAsFixed(6);
      _longitudeController.text = _selectedLocation!.longitude.toStringAsFixed(6);
    }
  }
  
  void _selectLocationFromMap() {
    setState(() {
      _showMap = true;
    });
  }
  
  void _onMapTap(TapDownDetails details, MapController mapController) {
    final point = mapController.pointToLatLng(Point(details.localPosition.dx, details.localPosition.dy));
    if (point != null) {
      setState(() {
        _selectedLocation = point;
        _updateLocationControllers();
      });
    }
  }
  
  Future<void> _getCoordinatesFromAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('住所を入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // まずOpenStreetMap Nominatim APIを試す
    final success = await _tryNominatimAPI(address);
    
    if (!success) {
      // Nominatim APIが失敗した場合、代替手段として手動設定を提案
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('自動取得に失敗しました。地図から手動で選択してください。'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<bool> _tryNominatimAPI(String address) async {
    try {
      // OpenStreetMap Nominatim APIを使用して住所から座標を取得
      final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1&addressdetails=1&countrycodes=jp';
      print('API URL: $url'); // デバッグ用
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'GourMap/1.0 (Flutter App)',
          'Accept': 'application/json',
        },
      );
      
      print('Response status: ${response.statusCode}'); // デバッグ用
      print('Response body: ${response.body}'); // デバッグ用
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          
          setState(() {
            _selectedLocation = LatLng(lat, lon);
            _updateLocationControllers();
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('座標を取得しました: ${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return true;
        } else {
          print('Empty response data');
          return false;
        }
      } else {
        print('HTTP Error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception in _tryNominatimAPI: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ネットワークエラー: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // 店舗アイコン画像を選択
  Future<void> _pickIconImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        if (kIsWeb) {
          // Webプラットフォームの場合、URLとして保存
          setState(() {
            _selectedIconImage = null;
            _iconImageUrl = image.path; // WebではpathがURLになる
          });
        } else {
          // モバイルプラットフォームの場合、Fileとして保存
          setState(() {
            _selectedIconImage = File(image.path);
            _iconImageUrl = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像選択エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 店舗イメージ画像を選択
  Future<void> _pickStoreImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 800, // 2:1の比率
        imageQuality: 80,
      );
      
      if (image != null) {
        if (kIsWeb) {
          // Webプラットフォームの場合、URLとして保存
          setState(() {
            _selectedStoreImage = null;
            _storeImageUrl = image.path; // WebではpathがURLになる
          });
        } else {
          // モバイルプラットフォームの場合、Fileとして保存
          setState(() {
            _selectedStoreImage = File(image.path);
            _storeImageUrl = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗イメージ画像選択エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 店舗アイコン画像をアップロード
  Future<String?> _uploadIconImage() async {
    if (_selectedIconImage == null && _iconImageUrl == null) return null;
    
    try {
      setState(() {
        _isUploadingIcon = true;
      });
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');
      
      // 店舗IDを生成（一時的なもの）
      final tempStoreId = FirebaseFirestore.instance.collection('stores').doc().id;
      
      String downloadUrl;
      
      if (kIsWeb && _iconImageUrl != null) {
        // Webプラットフォームの場合、URLから画像データを取得してFirebase Storageにアップロード
        try {
          final response = await http.get(Uri.parse(_iconImageUrl!));
          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('store_icons')
                .child('${user.uid}_$tempStoreId.jpg');
            
            final uploadTask = storageRef.putData(bytes);
            final snapshot = await uploadTask;
            downloadUrl = await snapshot.ref.getDownloadURL();
          } else {
            throw Exception('画像の取得に失敗しました');
          }
        } catch (e) {
          throw Exception('Web画像のアップロードに失敗しました: $e');
        }
      } else if (_selectedIconImage != null) {
        // モバイルプラットフォームの場合、Firebase Storageにアップロード
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('store_icons')
            .child('${user.uid}_$tempStoreId.jpg');
        
        final uploadTask = storageRef.putFile(_selectedIconImage!);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else {
        throw Exception('画像が選択されていません');
      }
      
      setState(() {
        _iconImageUrl = downloadUrl;
        _isUploadingIcon = false;
      });
      
      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploadingIcon = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像アップロードエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
  
  // 店舗イメージ画像をアップロード
  Future<String?> _uploadStoreImage() async {
    if (_selectedStoreImage == null && _storeImageUrl == null) return null;
    
    try {
      setState(() {
        _isUploadingStoreImage = true;
      });
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');
      
      // 店舗IDを生成（一時的なもの）
      final tempStoreId = FirebaseFirestore.instance.collection('stores').doc().id;
      
      String downloadUrl;
      
      if (kIsWeb && _storeImageUrl != null) {
        // Webプラットフォームの場合、URLから画像データを取得してFirebase Storageにアップロード
        try {
          final response = await http.get(Uri.parse(_storeImageUrl!));
          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('store_images')
                .child('${user.uid}_$tempStoreId.jpg');
            
            final uploadTask = storageRef.putData(bytes);
            final snapshot = await uploadTask;
            downloadUrl = await snapshot.ref.getDownloadURL();
          } else {
            throw Exception('画像の取得に失敗しました');
          }
        } catch (e) {
          throw Exception('Web画像のアップロードに失敗しました: $e');
        }
      } else if (_selectedStoreImage != null) {
        // モバイルプラットフォームの場合、Firebase Storageにアップロード
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('store_images')
            .child('${user.uid}_$tempStoreId.jpg');
        
        final uploadTask = storageRef.putFile(_selectedStoreImage!);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else {
        throw Exception('画像が選択されていません');
      }
      
      setState(() {
        _storeImageUrl = downloadUrl;
        _isUploadingStoreImage = false;
      });
      
      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploadingStoreImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗イメージ画像アップロードエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _xController.dispose();
    _facebookController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _tagsController.dispose();
    
    // 営業時間のコントローラーを破棄
    for (var controllers in _businessHoursControllers.values) {
      controllers['open']?.dispose();
      controllers['close']?.dispose();
    }
    
    super.dispose();
  }

  Future<void> _createStore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // 店舗アイコン画像をアップロード
      String? iconImageUrl;
      if (_selectedIconImage != null || _iconImageUrl != null) {
        iconImageUrl = await _uploadIconImage();
        if (iconImageUrl == null) {
          throw Exception('店舗アイコンのアップロードに失敗しました');
        }
      }
      
      // 店舗イメージ画像をアップロード
      String? storeImageUrl;
      if (_selectedStoreImage != null || _storeImageUrl != null) {
        storeImageUrl = await _uploadStoreImage();
        if (storeImageUrl == null) {
          throw Exception('店舗イメージ画像のアップロードに失敗しました');
        }
      }

      // 店舗IDを生成
      final storeId = FirebaseFirestore.instance.collection('stores').doc().id;
      
      // Firestoreに店舗情報を保存
      await FirebaseFirestore.instance.collection('stores').doc(storeId).set({
        'storeId': storeId,
        'name': _storeNameController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'category': _selectedCategory,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isApproved': false, // 審査待ち状態
        'goldStamps': 0,
        'totalVisitors': 0,
        'averageRating': 0.0,
        'totalRatings': 0,
        'iconImageUrl': iconImageUrl, // 店舗アイコン画像URL
        'storeImageUrl': storeImageUrl, // 店舗イメージ画像URL
        'location': {
          'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
          'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
        },
        'businessHours': {
          'monday': {
            'open': _businessHoursControllers['monday']!['open']!.text,
            'close': _businessHoursControllers['monday']!['close']!.text,
            'isOpen': _businessDaysOpen['monday'] ?? false
          },
          'tuesday': {
            'open': _businessHoursControllers['tuesday']!['open']!.text,
            'close': _businessHoursControllers['tuesday']!['close']!.text,
            'isOpen': _businessDaysOpen['tuesday'] ?? false
          },
          'wednesday': {
            'open': _businessHoursControllers['wednesday']!['open']!.text,
            'close': _businessHoursControllers['wednesday']!['close']!.text,
            'isOpen': _businessDaysOpen['wednesday'] ?? false
          },
          'thursday': {
            'open': _businessHoursControllers['thursday']!['open']!.text,
            'close': _businessHoursControllers['thursday']!['close']!.text,
            'isOpen': _businessDaysOpen['thursday'] ?? false
          },
          'friday': {
            'open': _businessHoursControllers['friday']!['open']!.text,
            'close': _businessHoursControllers['friday']!['close']!.text,
            'isOpen': _businessDaysOpen['friday'] ?? false
          },
          'saturday': {
            'open': _businessHoursControllers['saturday']!['open']!.text,
            'close': _businessHoursControllers['saturday']!['close']!.text,
            'isOpen': _businessDaysOpen['saturday'] ?? false
          },
          'sunday': {
            'open': _businessHoursControllers['sunday']!['open']!.text,
            'close': _businessHoursControllers['sunday']!['close']!.text,
            'isOpen': _businessDaysOpen['sunday'] ?? false
          },
        },
        'tags': _tags,
        'images': [], // 後で画像を追加可能
        'socialMedia': {
          'instagram': _instagramController.text.trim(),
          'x': _xController.text.trim(),
          'facebook': _facebookController.text.trim(),
          'website': _websiteController.text.trim(),
        },
      });
      
      // 作成者の店舗リストにも追加
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'createdStores': FieldValue.arrayUnion([storeId]),
      });

      if (mounted) {
        // 成功ダイアログを表示
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '店舗作成完了',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '「${_storeNameController.text.trim()}」が正常に作成されました！',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '店舗ID: $storeId',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '※ 店舗は審査後に公開されます。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // 前の画面に戻る
                  },
                  child: const Text('OK'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗作成に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: const Text(
              '新規店舗作成',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.store,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '新しい店舗を登録',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'お客様に素晴らしい体験を提供しましょう',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 店舗名
                  _buildInputField(
                    controller: _storeNameController,
                    label: '店舗名 *',
                    hint: '例：GrouMap店舗',
                    icon: Icons.store,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '店舗名を入力してください';
                      }
                      if (value.trim().length < 2) {
                        return '店舗名は2文字以上で入力してください';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // カテゴリ
                  _buildCategoryDropdown(),
                  
                  const SizedBox(height: 20),
                  
                  // 店舗アイコン画像
                  _buildIconImageSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 店舗イメージ画像
                  _buildStoreImageSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 住所
              _buildInputField(
                controller: _addressController,
                label: '住所 *',
                hint: '例：埼玉県川口市芝5-5-13',
                icon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '住所を入力してください';
                  }
                  return null;
                },
              ),
              
              // 住所から座標取得ボタン
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getCoordinatesFromAddress,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search, size: 18),
                  label: Text(_isLoading ? '座標取得中...' : '住所から座標を取得'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
                  
                  const SizedBox(height: 20),
                  
                  // 電話番号
                  _buildInputField(
                    controller: _phoneController,
                    label: '電話番号',
                    hint: '例：03-1234-5678',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 店舗説明
                  _buildInputField(
                    controller: _descriptionController,
                    label: '店舗説明',
                    hint: '店舗の特徴や魅力を説明してください',
                    icon: Icons.description,
                    maxLines: 4,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 位置情報
                  _buildLocationSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 営業時間
                  _buildBusinessHoursSection(),
                  
                  const SizedBox(height: 20),
                  
                  // タグ
                  _buildTagsSection(),
                  
                  const SizedBox(height: 20),
                  
                  // SNS・ウェブサイト
                  _buildSocialMediaSection(),
                  
                  const SizedBox(height: 32),
                  
                  // 作成ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '店舗を作成してデータベースに保存',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 注意事項
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '店舗作成後、審査を経て公開されます。虚偽の情報は禁止されています。',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // メニュー作成ボタン
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.restaurant_menu,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'メニュー管理',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '店舗作成後、メニューの追加・編集ができます。',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // メニュー管理画面に遷移
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => MenuManagementView(
                                    storeId: '', // 店舗作成前なので空文字
                                    isEditing: false,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('メニューを作成'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // マップ選択ダイアログ
        if (_showMap) _buildMapDialog(),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'カテゴリ *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '店舗アイコン画像',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              // 現在の画像表示
              if (_selectedIconImage != null || _iconImageUrl != null)
                Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: _selectedIconImage != null
                        ? (kIsWeb 
                            ? Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              )
                            : Image.file(
                                _selectedIconImage!,
                                fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
                              )
                          )
                        : _iconImageUrl != null
                            ? Image.network(
                                _iconImageUrl!,
                                fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : null,
                  ),
                ),
              
              // 画像選択ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickIconImage,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('画像を選択'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              Text(
                '推奨サイズ: 512x512px、JPG形式',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStoreImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '店舗イメージ画像',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              // 現在の画像表示
              if (_selectedStoreImage != null || _storeImageUrl != null)
                Container(
                  width: 400,
                  height: 200, // 2:1の比率
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedStoreImage != null
                        ? (kIsWeb 
                            ? Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              )
                            : Image.file(
                                _selectedStoreImage!,
                                fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
                              )
                          )
                        : _storeImageUrl != null
                            ? Image.network(
                                _storeImageUrl!,
                                fit: BoxFit.cover, // アスペクト比を保ちながら、不要部分を切り取って表示
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : null,
                  ),
                ),
              
              // 画像選択ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickStoreImage,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('店舗イメージ画像を選択'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              Text(
                '推奨サイズ: 1600x800px（2:1比率）、JPG形式',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '位置情報',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _selectLocationFromMap,
              icon: const Icon(Icons.map, size: 18),
              label: const Text('地図から選択'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _latitudeController,
                label: '緯度',
                hint: '例：35.6581',
                icon: Icons.location_on,
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                controller: _longitudeController,
                label: '経度',
                hint: '例：139.7017',
                icon: Icons.location_on,
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
            ),
          ],
        ),
        if (_selectedLocation != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      '位置が設定されました',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '緯度: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '経度: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBusinessHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '営業時間',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildBusinessDayRow('月曜日', 'monday'),
              const Divider(),
              _buildBusinessDayRow('火曜日', 'tuesday'),
              const Divider(),
              _buildBusinessDayRow('水曜日', 'wednesday'),
              const Divider(),
              _buildBusinessDayRow('木曜日', 'thursday'),
              const Divider(),
              _buildBusinessDayRow('金曜日', 'friday'),
              const Divider(),
              _buildBusinessDayRow('土曜日', 'saturday'),
              const Divider(),
              _buildBusinessDayRow('日曜日', 'sunday'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessDayRow(String dayName, String dayKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              dayName,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Switch(
            value: _businessDaysOpen[dayKey] ?? true,
            onChanged: (value) {
              setState(() {
                _businessDaysOpen[dayKey] = value;
              });
            },
            activeColor: const Color(0xFFFF6B35),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTimePicker(
                    controller: _businessHoursControllers[dayKey]!['open']!,
                    enabled: _businessDaysOpen[dayKey] ?? true,
                    label: '開店時間',
                  ),
                ),
                const SizedBox(width: 8),
                const Text('〜'),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimePicker(
                    controller: _businessHoursControllers[dayKey]!['close']!,
                    enabled: _businessDaysOpen[dayKey] ?? true,
                    label: '閉店時間',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({
    required TextEditingController controller,
    required bool enabled,
    required String label,
  }) {
    return GestureDetector(
      onTap: enabled ? () => _showTimePickerDialog(controller) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: enabled ? Colors.white : Colors.grey[100],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.text.isEmpty ? '時間を選択' : controller.text,
                style: TextStyle(
                  fontSize: 14,
                  color: enabled ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ),
            if (enabled)
              const Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }





  void _showTimePickerDialog(TextEditingController controller) {
    // 現在の時間を解析
    TimeOfDay currentTime = TimeOfDay.now();
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        if (parts.length == 2) {
          currentTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        // パースエラーの場合は現在時刻を使用
      }
    }

    int selectedHour = currentTime.hour;
    int selectedMinute = currentTime.minute;
    
    // 分を5分単位に調整
    selectedMinute = (selectedMinute / 5).round() * 5;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('時間を選択'),
              content: SizedBox(
                height: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 時間選択
                    Expanded(
                      child: ListWheelScrollView(
                        itemExtent: 50,
                        diameterRatio: 1.5,
                        controller: FixedExtentScrollController(initialItem: selectedHour),
                        onSelectedItemChanged: (index) {
                          setDialogState(() {
                            selectedHour = index;
                          });
                        },
                        children: List.generate(24, (index) {
                          return Center(
                            child: Text(
                              '${index.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: selectedHour == index ? FontWeight.bold : FontWeight.normal,
                                color: selectedHour == index ? const Color(0xFFFF6B35) : Colors.black87,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    // 分選択（5分単位）
                    Expanded(
                      child: ListWheelScrollView(
                        itemExtent: 50,
                        diameterRatio: 1.5,
                        controller: FixedExtentScrollController(initialItem: selectedMinute ~/ 5),
                        onSelectedItemChanged: (index) {
                          setDialogState(() {
                            selectedMinute = index * 5;
                          });
                        },
                        children: List.generate(12, (index) {
                          final minute = index * 5;
                          return Center(
                            child: Text(
                              '${minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: selectedMinute == minute ? FontWeight.bold : FontWeight.normal,
                                color: selectedMinute == minute ? const Color(0xFFFF6B35) : Colors.black87,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    // 選択された時間をコントローラーに設定
                    final timeString = '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                    controller.text = timeString;
                    // 画面を更新
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'タグ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  hintText: '例：カフェ、本屋、Wi-Fi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addTag,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('追加'),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
              label: Text(tag),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _removeTag(tag),
              backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SNS・ウェブサイト',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _websiteController,
          label: 'ウェブサイト',
          hint: '例：https://example.com',
          icon: Icons.language,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _instagramController,
                label: 'Instagram',
                hint: '例：https://instagram.com/username',
                icon: Icons.camera_alt,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                controller: _xController,
                label: 'X (Twitter)',
                hint: '例：https://x.com/username',
                icon: Icons.flutter_dash,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _facebookController,
          label: 'Facebook',
          hint: '例：https://facebook.com/page',
          icon: Icons.facebook,
        ),
      ],
    );
  }
  
  Widget _buildMapDialog() {
    final mapController = MapController();
    final searchController = TextEditingController();
    LatLng? searchResult;
    
    return StatefulBuilder(
      builder: (context, setDialogState) {
        
        return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.map, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '位置を選択してください',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showMap = false;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // 住所検索バー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: '住所を入力して検索...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                          borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final address = searchController.text.trim();
                      if (address.isNotEmpty) {
                        final success = await _tryNominatimAPI(address);
                        if (success && _selectedLocation != null) {
                          setDialogState(() {
                            searchResult = _selectedLocation;
                          });
                          // 地図を検索結果の位置に移動
                          mapController.move(_selectedLocation!, 15.0);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('検索'),
                  ),
                ],
              ),
            ),
            
            // マップ
            Expanded(
              child: GestureDetector(
                onTapDown: (details) {
                  _onMapTap(details, mapController);
                  setDialogState(() {
                    // 手動選択時は検索結果をクリア
                    searchResult = null;
                  });
                },
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ?? const LatLng(35.6581, 139.7017),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    // 選択された位置のマーカー
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFFFF6B35),
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    // 検索結果のマーカー（青いピン）
                    if (searchResult != null && searchResult != _selectedLocation)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: searchResult!,
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // フッター
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedLocation != null) ...[
                          const Text(
                            '選択された位置:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                          Text(
                            '緯度: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFFF6B35),
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            '経度: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFFF6B35),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ] else if (searchResult != null) ...[
                          const Text(
                            '検索結果:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            '緯度: ${searchResult!.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            '経度: ${searchResult!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ] else ...[
                          Text(
                            '地図をタップして位置を選択してください',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _selectedLocation != null
                        ? () {
                            setState(() {
                              _showMap = false;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('確定'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
} 