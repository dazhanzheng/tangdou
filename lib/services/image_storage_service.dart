import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/gallery_image.dart';
import '../utils/color_analyzer.dart';

// 排序类型枚举
enum SortType {
  name,        // 按名称排序
  uploadTime,  // 按上传时间排序（默认）
  color        // 按颜色排序
}

class ImageStorageService {
  static const String _imagesKey = 'gallery_images';
  static const String _sortTypeKey = 'gallery_sort_type';
  
  // 获取应用专属目录
  Future<Directory> get _appDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/gallery_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }
  
  // 检查并请求权限
  Future<bool> requestPermissions() async {
    // 在Android上，需要请求多个权限
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) 使用更细化的媒体权限
      if (await _isAndroid13OrHigher()) {
        final status = await Permission.photos.request();
        return status.isGranted || status.isLimited;
      } else {
        // Android 13以下版本使用存储权限
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          return false;
        }
      }
      // 相机权限单独请求
      final cameraStatus = await Permission.camera.request();
      return cameraStatus.isGranted;
    }
    
    // iOS会通过image_picker自动请求权限
    return true;
  }
  
  // 检查相机权限
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  
  // 检查是否为Android 13或以上版本
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    return await Permission.photos.status.isGranted || 
           await Permission.photos.status.isDenied ||
           await Permission.photos.status.isPermanentlyDenied;
  }
  
  // 保存图片到本地存储并添加元数据
  Future<GalleryImage?> saveImage(File imageFile, {String? customName}) async {
    try {
      final appDir = await _appDirectory;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'image_$timestamp.$extension';
      final savedImage = await imageFile.copy('${appDir.path}/$fileName');
      
      // 分析图片颜色（多个主色）
      final dominantColors = await ColorAnalyzer.analyzeImageColors(savedImage.path);
      
      // 创建图片元数据
      final imageName = customName ?? 'Image_$timestamp';
      final galleryImage = GalleryImage(
        path: savedImage.path,
        name: imageName,
        uploadTime: DateTime.now(),
        dominantColors: dominantColors,
      );
      
      // 保存图片元数据
      await _saveImageMetadata(galleryImage);
      
      return galleryImage;
    } catch (e) {
      print('保存图片时出错: $e');
      return null;
    }
  }
  
  // 将图片元数据保存到SharedPreferences
  Future<void> _saveImageMetadata(GalleryImage image) async {
    final prefs = await SharedPreferences.getInstance();
    final existingImagesJson = prefs.getStringList(_imagesKey) ?? [];
    
    // 转换现有数据为图片对象
    final List<GalleryImage> images = existingImagesJson
        .map((json) => GalleryImage.fromJson(jsonDecode(json)))
        .toList();
    
    // 检查是否已存在该图片
    final existingIndex = images.indexWhere((img) => img.path == image.path);
    if (existingIndex >= 0) {
      images[existingIndex] = image;
    } else {
      images.add(image);
    }
    
    // 保存更新后的列表
    final updatedImagesJson = images
        .map((img) => jsonEncode(img.toJson()))
        .toList();
    
    await prefs.setStringList(_imagesKey, updatedImagesJson);
  }
  
  // 获取所有图片，支持按指定排序方式排序
  Future<List<GalleryImage>> getAllImages({SortType? sortType}) async {
    final prefs = await SharedPreferences.getInstance();
    final imagesJson = prefs.getStringList(_imagesKey) ?? [];
    
    // 如果未指定排序方式，使用保存的设置或默认排序
    sortType ??= _getSortTypeFromPrefs(prefs);
    
    // 转换JSON为对象并过滤掉不存在的图片文件
    final List<GalleryImage> images = [];
    for (final json in imagesJson) {
      try {
        final image = GalleryImage.fromJson(jsonDecode(json));
        final file = File(image.path);
        if (await file.exists()) {
          images.add(image);
        }
      } catch (e) {
        print('解析图片数据错误: $e');
      }
    }
    
    // 根据排序类型排序
    _sortImages(images, sortType);
    
    return images;
  }
  
  // 获取保存的排序方式设置
  SortType _getSortTypeFromPrefs(SharedPreferences prefs) {
    final sortIndex = prefs.getInt(_sortTypeKey);
    return sortIndex != null 
        ? SortType.values[sortIndex] 
        : SortType.uploadTime; // 默认按上传时间排序
  }
  
  // 获取当前排序方式
  Future<SortType> getCurrentSortType() async {
    final prefs = await SharedPreferences.getInstance();
    return _getSortTypeFromPrefs(prefs);
  }
  
  // 保存排序方式设置
  Future<void> saveSortType(SortType sortType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortTypeKey, sortType.index);
  }
  
  // 根据排序类型对图片进行排序
  void _sortImages(List<GalleryImage> images, SortType sortType) {
    switch (sortType) {
      case SortType.name:
        images.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortType.uploadTime:
        images.sort((a, b) => b.uploadTime.compareTo(a.uploadTime)); // 最新的优先显示
        break;
      case SortType.color:
        // 使用新的多主色排序逻辑
        images.sort((a, b) => 
          ColorAnalyzer.calculateColorsWeight(a.dominantColors)
              .compareTo(ColorAnalyzer.calculateColorsWeight(b.dominantColors))
        );
        break;
    }
  }
  
  // 更新图片名称
  Future<bool> updateImageName(String imagePath, String newName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = prefs.getStringList(_imagesKey) ?? [];
      
      // 转换所有图片为对象
      final List<GalleryImage> images = imagesJson
          .map((json) => GalleryImage.fromJson(jsonDecode(json)))
          .toList();
      
      // 查找要更新的图片
      final index = images.indexWhere((img) => img.path == imagePath);
      if (index >= 0) {
        // 创建新的对象并更新名称
        final updatedImage = GalleryImage(
          path: images[index].path,
          name: newName,
          uploadTime: images[index].uploadTime,
          dominantColors: images[index].dominantColors,
        );
        
        // 更新列表
        images[index] = updatedImage;
        
        // 保存更新后的列表
        final updatedImagesJson = images
            .map((img) => jsonEncode(img.toJson()))
            .toList();
        
        await prefs.setStringList(_imagesKey, updatedImagesJson);
        return true;
      }
      
      return false;
    } catch (e) {
      print('更新图片名称错误: $e');
      return false;
    }
  }
  
  // 删除图片
  Future<bool> deleteImage(String imagePath) async {
    try {
      // 删除文件
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // 从元数据中移除
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = prefs.getStringList(_imagesKey) ?? [];
      
      final List<GalleryImage> images = imagesJson
          .map((json) => GalleryImage.fromJson(jsonDecode(json)))
          .toList();
      
      // 过滤掉要删除的图片
      final updatedImages = images.where((img) => img.path != imagePath).toList();
      
      // 更新SharedPreferences
      final updatedImagesJson = updatedImages
          .map((img) => jsonEncode(img.toJson()))
          .toList();
      
      await prefs.setStringList(_imagesKey, updatedImagesJson);
      
      return true;
    } catch (e) {
      print('删除图片时出错: $e');
      return false;
    }
  }
  
  // 兼容旧版本数据的方法 - 获取单纯的图片路径列表
  Future<List<String>> getAllImagePaths() async {
    final images = await getAllImages();
    return images.map((img) => img.path).toList();
  }
} 