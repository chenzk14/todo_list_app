import 'package:flutter/material.dart';
import 'home_page.dart';
import 'statistics_page.dart';
import 'data_management_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '一键打卡 APP',
      theme: ThemeData(
        primaryColor: Color(0xFF007AFF), // Apple 科技蓝
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF007AFF),
          primary: Color(0xFF007AFF),
          secondary: Color(0xFF5AC8FA),
        ),
        scaffoldBackgroundColor: Color(0xFFF2F2F7), // Apple 浅灰背景
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF007AFF),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    StatisticsPage(),
    DataManagementPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.backup),
            label: '数据管理',
          ),
        ],
      ),
    );
  }
}