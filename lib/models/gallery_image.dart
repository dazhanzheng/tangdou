import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

/// 图库图片模型
class GalleryImage {
  final String path;         // 图片文件路径
  final String name;         // 图片名称
  final DateTime uploadTime; // 上传时间
  final List<Color> dominantColors; // 主要颜色列表(按比例从大到小排序)

  GalleryImage({
    required this.path,
    required this.name,
    required this.uploadTime,
    required this.dominantColors,
  });

  // 获取主色调（第一主色）
  Color get primaryColor => dominantColors.isNotEmpty ? dominantColors[0] : Colors.grey;

  // 从JSON解析
  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    // 解析颜色列表
    final colorValues = json['dominantColors'] as List<dynamic>? ?? [];
    final colors = colorValues.map((value) => Color(value as int)).toList();
    
    // 确保至少有一个默认颜色
    if (colors.isEmpty) {
      colors.add(Colors.grey);
    }
    
    return GalleryImage(
      path: json['path'] as String,
      name: json['name'] as String,
      uploadTime: DateTime.fromMillisecondsSinceEpoch(json['uploadTime'] as int),
      dominantColors: colors,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'uploadTime': uploadTime.millisecondsSinceEpoch,
      'dominantColors': dominantColors.map((color) => color.value).toList(),
    };
  }
} 