import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          const UserInfoCard(),
          
          // 功能列表
          _buildFunctionItem(context, Icons.settings, '设置'),
          _buildFunctionItem(context, Icons.favorite, '我的收藏'),
          _buildFunctionItem(context, Icons.history, '浏览历史'),
          _buildFunctionItem(context, Icons.help_outline, '帮助与反馈'),
          _buildFunctionItem(context, Icons.info_outline, '关于糖豆'),
        ],
      ),
    );
  }
  
  Widget _buildFunctionItem(BuildContext context, IconData icon, String title) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // 点击功能项的逻辑
        },
      ),
    );
  }
}

class UserInfoCard extends StatelessWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.pink.shade100,
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.pink,
            ),
          ),
          const SizedBox(width: 16),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '点击登录',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '登录体验更多功能',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // 箭头
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
} 