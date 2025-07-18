# 糖豆 App

一个使用Flutter开发的移动应用程序。

## 功能模块

### 1. 图库模块
- 提供网格布局展示本地图片内容
- 支持从相册选择图片添加到应用
- 支持通过相机拍摄照片添加到应用
- 长按图片可以删除
- 点击图片查看大图
- 本地图库存储，无需网络连接
- 图片命名与编辑功能，可自定义每张图片的名称
- 多种排序方式：按名称、上传时间或颜色排序
- 颜色分析功能，自动提取图片主要颜色
- 排序设置持久化，即使重启应用也能保持用户设定

### 2. 发现模块
- 显示推荐内容列表
- 每个内容项可点击查看详情

### 3. 个人中心模块
- 用户信息卡片展示
- 设置、收藏、浏览历史等功能入口
- 帮助与反馈通道
- 关于应用信息

## 技术特点
- 模块化的代码结构
- 使用Flutter的Material Design组件
- 统一的设计风格
- 本地存储管理图片文件
- 图片缩略图预览与全屏查看
- 图片元数据管理与持久化
- 智能颜色分析算法

## 项目结构
```
lib/
  ├── main.dart                     # 应用入口文件
  ├── models/                       # 数据模型
  │    └── gallery_image.dart       # 图库图片模型
  ├── services/                     # 服务层
  │    └── image_storage_service.dart    # 图片存储服务
  ├── utils/                        # 工具类
  │    └── color_analyzer.dart      # 颜色分析工具
  └── screens/                      # 页面目录
       ├── gallery_screen.dart      # 图库页面
       ├── discover_screen.dart     # 发现页面
       └── profile_screen.dart      # 个人中心页面
```

## 使用的权限
- 相机权限：用于拍摄照片
- 存储权限：用于读取和保存图片
