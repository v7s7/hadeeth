import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../categories/categories_screen.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';

/// الإطار الرئيسي: شريط تنقل سفلي على الجوال، شريط جانبي على الويب.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    CategoriesScreen(),
    SearchScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  void _onTap(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final isWideWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 800;

    if (isWideWeb) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // الشريط الجانبي (على اليمين في RTL)
            _WebSidebar(selectedIndex: _index, onTap: _onTap),
            // محتوى الشاشة
            Expanded(
              child: IndexedStack(index: _index, children: _screens),
            ),
          ],
        ),
      );
    }

    // تخطيط الجوال - شريط تنقل سفلي
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'التصنيفات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'البحث',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'المفضلة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// الشريط الجانبي للويب
// ─────────────────────────────────────────────────────────────

class _WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _WebSidebar({required this.selectedIndex, required this.onTap});

  static const _items = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'الرئيسية'),
    _NavItem(Icons.category_rounded, Icons.category_outlined, 'التصنيفات'),
    _NavItem(Icons.search_rounded, Icons.search_outlined, 'البحث'),
    _NavItem(Icons.bookmark_rounded, Icons.bookmark_outline, 'المفضلة'),
    _NavItem(Icons.person_rounded, Icons.person_outline, 'حسابي'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(
          // الحد الفاصل بين الشريط والمحتوى (على اليسار في RTL)
          left: BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      child: SafeArea(
        left: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── الشعار ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: AppColors.primaryDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'الحديث\nالمهجور',
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.12), height: 1),
            const SizedBox(height: 10),

            // ── عناصر التنقل ──
            for (int i = 0; i < _items.length; i++)
              _SidebarNavTile(
                icon: selectedIndex == i ? _items[i].activeIcon : _items[i].icon,
                label: _items[i].label,
                selected: selectedIndex == i,
                onTap: () => onTap(i),
              ),

            const Spacer(),

            // ── الإصدار ──
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'الإصدار ١.٠',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  color: Colors.white30,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// بيانات عنصر التنقل
class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;

  const _NavItem(this.activeIcon, this.icon, this.label);
}

// عنصر تنقل واحد في الشريط الجانبي
class _SidebarNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          hoverColor: Colors.white10,
          splashColor: Colors.white12,
          highlightColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? Colors.white : Colors.white60,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: GoogleFonts.tajawal(
                    color: selected ? Colors.white : Colors.white60,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
