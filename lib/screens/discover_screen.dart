import 'package:flutter/material.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: 15, // 示例数量
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.primaries[index % Colors.primaries.length],
                child: Icon(Icons.explore, color: Colors.white),
              ),
              title: Text('发现内容 ${index + 1}'),
              subtitle: Text('这是关于发现内容的简短描述'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // 点击内容的逻辑
              },
            ),
          );
        },
      ),
    );
  }
} 