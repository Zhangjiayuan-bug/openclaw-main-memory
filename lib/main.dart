import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workflow_app/config/theme.dart';
import 'package:workflow_app/providers/project_provider.dart';
import 'package:workflow_app/screens/home_screen.dart';
import 'package:workflow_app/screens/settings_screen.dart';

void main() {
  runApp(const WorkflowApp());
}

class WorkflowApp extends StatelessWidget {
  const WorkflowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectProvider()..init(),
      child: MaterialApp(
        title: '工作流助手',
        debugShowCheckedModeBanner: false,
        theme: TechTheme.darkTheme,
        home: const MainScreen(),
      ),
    );
  }
}

/// 主屏幕（带底部导航）
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: TechTheme.darkNightBlue,
          border: Border(
            top: BorderSide(
              color: TechTheme.starGrayBlue,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, '首页'),
                _buildNavItem(1, Icons.settings_outlined, Icons.settings, '设置'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: TechTheme.electricCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TechTheme.electricCyan.withOpacity(0.3),
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? TechTheme.electricCyan : TechTheme.silverGray,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? TechTheme.electricCyan : TechTheme.silverGray,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
