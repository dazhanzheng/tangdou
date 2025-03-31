import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_storage_service.dart';
import '../models/gallery_image.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImageStorageService _storageService = ImageStorageService();
  final ImagePicker _imagePicker = ImagePicker();
  List<GalleryImage> _images = [];
  bool _isLoading = true;
  SortType _currentSortType = SortType.uploadTime; // 默认排序方式

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  // 加载已保存的图片
  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取当前排序方式
      _currentSortType = await _storageService.getCurrentSortType();
      
      // 加载图片
      final images = await _storageService.getAllImages(sortType: _currentSortType);
      setState(() {
        _images = images;
        _isLoading = false;
      });
    } catch (e) {
      print('加载图片时出错: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 切换排序方式
  Future<void> _changeSortType(SortType newSortType) async {
    if (newSortType == _currentSortType) return;
    
    await _storageService.saveSortType(newSortType);
    setState(() {
      _currentSortType = newSortType;
    });
    
    // 重新加载图片
    await _loadImages();
  }

  // 从图库选择图片
  Future<void> _pickImageFromGallery() async {
    try {
      // 由image_picker和permission_handler插件触发系统权限请求
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // 弹出对话框询问图片名称
        final imageName = await _askForImageName(
          defaultName: 'Image_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (imageName != null) {
          final savedImage = await _storageService.saveImage(
            File(pickedFile.path),
            customName: imageName,
          );
          
          if (savedImage != null) {
            await _loadImages(); // 重新加载所有图片
          }
        }
      }
    } catch (e) {
      _showErrorDialog('选择图片时出错: $e');
    }
  }

  // 拍摄照片
  Future<void> _takePhoto() async {
    try {
      // 请求相机权限，会触发系统权限请求对话框
      final hasPermission = await _storageService.requestCameraPermission();
      if (!hasPermission) {
        _showErrorDialog('需要相机权限来拍摄照片');
        return;
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // 弹出对话框询问图片名称
        final imageName = await _askForImageName(
          defaultName: 'Image_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (imageName != null) {
          final savedImage = await _storageService.saveImage(
            File(pickedFile.path),
            customName: imageName,
          );
          
          if (savedImage != null) {
            await _loadImages(); // 重新加载所有图片
          }
        }
      }
    } catch (e) {
      _showErrorDialog('拍摄照片时出错: $e');
    }
  }

  // 询问用户输入图片名称
  Future<String?> _askForImageName({required String defaultName}) async {
    String name = defaultName;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('图片名称'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '输入图片名称',
            hintText: '例如：我的照片',
          ),
          onChanged: (value) {
            name = value.trim().isNotEmpty ? value.trim() : defaultName;
          },
          controller: TextEditingController(text: defaultName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    return confirmed == true ? name : null;
  }

  // 显示错误对话框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 显示图片详情
  void _showImageDetail(GalleryImage image) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageDetailScreen(
          image: image,
          onImageNameUpdated: _loadImages,
        ),
      ),
    );
  }

  // 编辑图片名称
  Future<void> _editImageName(GalleryImage image) async {
    final newName = await _askForImageName(defaultName: image.name);
    if (newName != null && newName != image.name) {
      final success = await _storageService.updateImageName(image.path, newName);
      if (success) {
        await _loadImages();
      }
    }
  }

  // 删除图片
  Future<void> _deleteImage(GalleryImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这张图片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _storageService.deleteImage(image.path);
      if (success) {
        setState(() {
          _images.remove(image);
        });
      } else {
        _showErrorDialog('删除图片失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图库'),
        centerTitle: true,
        actions: [
          // 排序按钮
          PopupMenuButton<SortType>(
            icon: const Icon(Icons.sort),
            tooltip: '排序方式',
            onSelected: _changeSortType,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortType.name,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('按名称排序'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortType.uploadTime,
                child: Row(
                  children: [
                    Icon(Icons.access_time),
                    SizedBox(width: 8),
                    Text('按上传时间排序'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortType.color,
                child: Row(
                  children: [
                    Icon(Icons.color_lens),
                    SizedBox(width: 8),
                    Text('按颜色排序'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadImages,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('从相册选择'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImageFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('拍摄照片'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _takePhoto();
                  },
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? _buildEmptyView()
              : _buildGalleryGrid(),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无图片',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickImageFromGallery,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('添加图片'),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8, // 调整宽高比，使得底部有空间显示名称
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        return GestureDetector(
          onTap: () => _showImageDetail(image),
          onLongPress: () => _deleteImage(image),
          child: Column(
            children: [
              Expanded(
                child: Hero(
                  tag: image.path,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(image.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                image.name,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建多主色指示器
  Widget _buildColorIndicators(List<Color> colors) {
    return Row(
      children: [
        // 限制最多显示4个主色
        for (int i = 0; i < colors.length && i < 4; i++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: colors[i],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
      ],
    );
  }
}

// 图片详情页面
class ImageDetailScreen extends StatelessWidget {
  final GalleryImage image;
  final VoidCallback onImageNameUpdated;
  final ImageStorageService _storageService = ImageStorageService();

  ImageDetailScreen({
    super.key, 
    required this.image,
    required this.onImageNameUpdated,
  });

  // 询问用户输入图片名称
  Future<String?> _askForImageName(BuildContext context, {required String defaultName}) async {
    String name = defaultName;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改图片名称'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '输入新名称',
            hintText: '例如：我的照片',
          ),
          onChanged: (value) {
            name = value.trim().isNotEmpty ? value.trim() : defaultName;
          },
          controller: TextEditingController(text: defaultName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    return confirmed == true ? name : null;
  }

  // 编辑图片名称
  Future<void> _editImageName(BuildContext context) async {
    final newName = await _askForImageName(context, defaultName: image.name);
    if (newName != null && newName != image.name) {
      final success = await _storageService.updateImageName(image.path, newName);
      if (success) {
        // 通知列表页刷新
        onImageNameUpdated();
        // 显示成功提示
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片名称已更新')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(image.name),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Hero(
              tag: image.path,
              child: Image.file(
                File(image.path),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图片名称与编辑按钮
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '名称: ${image.name}', 
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 添加编辑名称按钮
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      color: Colors.grey[700],
                      tooltip: '编辑名称',
                      onPressed: () => _editImageName(context),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '上传时间: ${image.uploadTime.year}/${image.uploadTime.month}/${image.uploadTime.day} ${image.uploadTime.hour}:${image.uploadTime.minute}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                // 主色调信息
                const Text('主要颜色:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _buildColorPalette(image.dominantColors),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建颜色调色板
  Widget _buildColorPalette(List<Color> colors) {
    return Builder(builder: (context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 最多显示4个主色
          for (int i = 0; i < colors.length && i < 4; i++)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Tooltip(
                message: '#${colors[i].value.toRadixString(16).substring(2).toUpperCase()}',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      // 显示颜色值
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '颜色: #${colors[i].value.toRadixString(16).substring(2).toUpperCase()}'
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
} 