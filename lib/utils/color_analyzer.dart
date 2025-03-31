import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 颜色分析工具类，用于提取图片的主要颜色
class ColorAnalyzer {
  // 色相区间数量
  static const int _hueSegments = 36; // 将色相分为36个区间
  // 要提取的主色数量
  static const int _dominantColorsCount = 4;
  
  /// 分析图片获取主要颜色（多个）
  /// 
  /// [imagePath] 图片文件路径
  /// 返回按占比排序的主要颜色列表
  static Future<List<Color>> analyzeImageColors(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return [Colors.grey]; // 默认颜色
      }

      // 读取图片文件
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 150); // 缩小尺寸提高性能
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      // 获取图片数据
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return [Colors.grey];
      }

      // 像素数据
      final pixels = byteData.buffer.asUint8List();
      
      // 色相分布桶 - 将HSV色相空间分为多个区间，统计每个区间的像素数
      final Map<int, _ColorBucket> hueBuckets = {};
      
      // 初始化色相桶
      for (int i = 0; i < _hueSegments; i++) {
        hueBuckets[i] = _ColorBucket();
      }
      
      // 总有效像素数（用于计算比例）
      int totalValidPixels = 0;
      
      // 遍历像素统计色相分布
      for (int i = 0; i < pixels.length; i += 4) {
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];
        final a = pixels[i + 3];
        
        // 跳过完全透明的像素
        if (a < 10) continue;
        
        // 创建颜色
        final color = Color.fromARGB(a, r, g, b);
        
        // 转换到HSV颜色空间
        final hsv = HSVColor.fromColor(color);
        
        // 跳过饱和度和明度太低的像素（接近黑色、白色、灰色）
        if (hsv.saturation < 0.15 || hsv.value < 0.15 || hsv.value > 0.95) continue;
        
        // 根据色相确定所属区间
        final hueSegment = ((hsv.hue / 360.0) * _hueSegments).floor() % _hueSegments;
        
        // 累加像素到相应的色相桶
        hueBuckets[hueSegment]!.addColor(color);
        totalValidPixels++;
      }
      
      // 如果有效像素太少，返回灰色
      if (totalValidPixels < 100) {
        return [Colors.grey];
      }
      
      // 找出占比最大的几个色相桶
      final List<MapEntry<int, _ColorBucket>> sortedBuckets = hueBuckets.entries.toList()
        ..sort((a, b) => b.value.pixelCount - a.value.pixelCount);
      
      // 提取主要颜色
      final List<Color> dominantColors = [];
      
      // 最多提取指定数量的主色
      for (int i = 0; i < _dominantColorsCount && i < sortedBuckets.length; i++) {
        if (sortedBuckets[i].value.pixelCount > 0) {
          // 计算该色相桶的平均颜色
          final avgColor = sortedBuckets[i].value.getAverageColor();
          dominantColors.add(avgColor);
        }
      }
      
      // 如果没有提取到任何主色，返回灰色
      if (dominantColors.isEmpty) {
        return [Colors.grey];
      }
      
      return dominantColors;
    } catch (e) {
      print('颜色分析错误: $e');
      return [Colors.grey];
    }
  }
  
  /// 计算颜色排序权重（用于基于多主色进行排序）
  /// 
  /// [colors] 颜色列表
  /// 返回一个复合权重值，用于排序
  static double calculateColorsWeight(List<Color> colors) {
    if (colors.isEmpty) return 0;
    
    // 将主色权重按权重递减，生成复合权重
    double weight = 0;
    double factor = 1.0;
    
    // 最多考虑前四个主色
    for (int i = 0; i < colors.length && i < 4; i++) {
      // 添加当前颜色的权重
      weight += _calculateSingleColorWeight(colors[i]) * factor;
      // 降低下一个颜色的权重影响
      factor *= 0.1;
    }
    
    return weight;
  }
  
  /// 计算单个颜色的排序权重
  /// 
  /// [color] 要计算的颜色
  /// 返回0-1之间的值
  static double _calculateSingleColorWeight(Color color) {
    // 转换为HSV以获取色相
    final HSVColor hsv = HSVColor.fromColor(color);
    
    // 使用色相值作为权重（归一化）
    return hsv.hue / 360.0;
  }
  
  /// 为了兼容性，保留旧的单色分析方法
  static Future<Color> analyzeImageColor(String imagePath) async {
    final colors = await analyzeImageColors(imagePath);
    return colors.first;
  }
}

/// 颜色统计桶，用于累计像素和计算平均颜色
class _ColorBucket {
  int pixelCount = 0;
  int totalR = 0;
  int totalG = 0;
  int totalB = 0;
  
  void addColor(Color color) {
    pixelCount++;
    totalR += color.red;
    totalG += color.green;
    totalB += color.blue;
  }
  
  Color getAverageColor() {
    if (pixelCount == 0) return Colors.grey;
    
    return Color.fromARGB(
      255,
      (totalR / pixelCount).round(),
      (totalG / pixelCount).round(),
      (totalB / pixelCount).round(),
    );
  }
} 