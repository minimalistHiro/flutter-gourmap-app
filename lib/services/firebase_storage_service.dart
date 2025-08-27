import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // プロフィール画像をアップロード
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      String fileName = 'profile_$userId.jpg';
      Reference ref = _storage.ref().child('profile_images/$fileName');
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('プロフィール画像のアップロードに失敗しました: $e');
    }
  }

  // 投稿画像をアップロード
  Future<List<String>> uploadPostImages(List<File> imageFiles, String postId) async {
    try {
      List<String> downloadUrls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        String fileName = 'post_${postId}_$i.jpg';
        Reference ref = _storage.ref().child('post_images/$fileName');
        
        UploadTask uploadTask = ref.putFile(imageFiles[i]);
        TaskSnapshot snapshot = await uploadTask;
        
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }
      
      return downloadUrls;
    } catch (e) {
      throw Exception('投稿画像のアップロードに失敗しました: $e');
    }
  }

  // クーポン画像をアップロード
  Future<String> uploadCouponImage(File imageFile, String couponId) async {
    try {
      String fileName = 'coupon_$couponId.jpg';
      Reference ref = _storage.ref().child('coupon_images/$fileName');
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('クーポン画像のアップロードに失敗しました: $e');
    }
  }

  // Web用：バイトデータからクーポン画像をアップロード
  Future<String> uploadCouponImageBytes(Uint8List imageBytes, String couponId) async {
    try {
      String fileName = 'coupon_$couponId.jpg';
      Reference ref = _storage.ref().child('coupon_images/$fileName');
      
      UploadTask uploadTask = ref.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('クーポン画像のアップロードに失敗しました: $e');
    }
  }

  // 店舗画像をアップロード
  Future<String> uploadStoreImage(File imageFile, String storeId) async {
    try {
      String fileName = 'store_$storeId.jpg';
      Reference ref = _storage.ref().child('store_images/$fileName');
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('店舗画像のアップロードに失敗しました: $e');
    }
  }

  // 画像を削除
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('画像の削除に失敗しました: $e');
    }
  }

  // カメラから画像を取得
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('カメラからの画像取得に失敗しました: $e');
    }
  }

  // ギャラリーから画像を取得
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('ギャラリーからの画像取得に失敗しました: $e');
    }
  }

  // 複数画像を取得
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      throw Exception('複数画像の取得に失敗しました: $e');
    }
  }
} 