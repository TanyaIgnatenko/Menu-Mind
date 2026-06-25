import 'package:flutter/material.dart';
import '../screens/scan_screen.dart';
import '../screens/history_screen.dart';
import '../theme/app_theme.dart';
import 'camera_glyph.dart';

/// Global key so any screen can switch tabs (e.g. empty-History CTA → Scan).
final appShellKey = GlobalKey<AppShellState>();

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int _index = 0;
  final _historyKey = GlobalKey<HistoryScreenState>();

  void switchTab(int index) {
    setState(() => _index = index);
    // The History screen lives in an IndexedStack (always mounted), so it won't
    // reload itself on tab change — refresh it when it becomes visible so a
    // just-scanned menu shows up immediately.
    if (index == 1) _historyKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _index,
        children: [const ScanScreen(), HistoryScreen(key: _historyKey)],
      ),
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onTap: switchTab,
      ),
    );
  }
}

/// Custom bottom navigation matching the Hot Dish spec: the active item shows a
/// filled primary icon tile + primary label; inactive items are muted.
class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF7FFFBF7), // canvas @ .97
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.only(top: 10, bottom: bottomInset > 0 ? bottomInset : 30),
      child: Row(
        children: [
          _NavItem(
            active: index == 0,
            icon: Icons.photo_camera_rounded,
            iconBuilder: (size, color) => CameraGlyph(size: size, color: color),
            label: 'Scan',
            onTap: () => onTap(0),
          ),
          _NavItem(
            active: index == 1,
            icon: Icons.history_rounded,
            label: 'History',
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool active;
  final IconData icon;

  /// Optional custom icon (size, color) — used for the camera glyph. Falls back
  /// to [icon] when null.
  final Widget Function(double size, Color color)? iconBuilder;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.active,
    required this.icon,
    this.iconBuilder,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active)
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: iconBuilder?.call(17, Colors.white) ??
                      Icon(icon, size: 17, color: Colors.white),
                )
              else
                iconBuilder?.call(26, AppColors.muted) ??
                    Icon(icon, size: 26, color: AppColors.muted),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.primary : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
