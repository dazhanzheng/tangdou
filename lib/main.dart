import 'package:flutter/material.dart';
import 'screens/gallery_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // 自定义粉色
  static const Color customPink = Color.fromRGBO(255, 103, 176, 1.0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '糖豆',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: _createMaterialColor(customPink),
        primaryColor: customPink,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: customPink,
          secondary: customPink,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
  
  // 创建MaterialColor，因为自定义颜色需要转换为MaterialColor以用作primarySwatch
  static MaterialColor _createMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  // 使用MainApp中定义的颜色
  static const Color customPink = MainApp.customPink;
  
  final List<Widget> _pages = [
    const GalleryScreen(),
    const DiscoverScreen(),
    const ProfileScreen(),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: '图库',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: '发现',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: customPink,
        onTap: _onItemTapped,
      ),
    );
  }
}
