import 'package:firebase_auth/firebase_auth.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'admin_manage_comics_screen.dart';
import 'admin_upload_screen.dart';
import 'tabs/library_tab.dart';
import 'tabs/simple_tab.dart';
import 'tabs/comics_tab.dart';
import 'tabs/search_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.profile,
    required this.themeService,
  });

  final UserProfile profile;
  final ThemeService themeService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _titles = <String>[
    'Tủ Sách',
    'Truyện',
    'Tìm Kiếm',
    'Thế Giới',
    'Tôi',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = <Widget>[
      LibraryTab(user: user, profile: widget.profile),
      ComicsTab(profile: widget.profile),
      SearchTab(profile: widget.profile),
      const SimpleTab(icon: Icons.public, title: 'Thế giới truyện'),
      _ProfileTab(
        user: user,
        profile: widget.profile,
        themeService: widget.themeService,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.react,
        initialActiveIndex: _currentIndex,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        activeColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        items: const [
          TabItem(icon: Icons.book, title: 'Tủ Sách'),
          TabItem(icon: Icons.menu_book, title: 'Truyện'),
          TabItem(icon: Icons.search, title: 'Tìm Kiếm'),
          TabItem(icon: Icons.language, title: 'Thế Giới'),
          TabItem(icon: Icons.person, title: 'Tôi'),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.user,
    required this.profile,
    required this.themeService,
  });

  final User user;
  final UserProfile profile;
  final ThemeService themeService;

  @override
  Widget build(BuildContext context) {
    final nameSource = profile.displayName.isNotEmpty
        ? profile.displayName
        : (user.displayName ?? user.email ?? 'T');
    final displayLetter = nameSource.isNotEmpty
        ? nameSource.trim()[0].toUpperCase()
        : 'T';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(
              displayLetter,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            profile.displayName.isNotEmpty
                ? profile.displayName
                : (user.displayName ?? 'Chua cap nhat ten'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(user.email ?? profile.email, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Chip(label: Text('VIP Level ${profile.vipLevel}')),
          const SizedBox(height: 24),
          // Dark Mode Toggle
          Card(
            child: SwitchListTile(
              title: const Text('Chế độ nền tối'),
              subtitle: const Text('Bật/tắt giao diện tối'),
              secondary: Icon(
                themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              value: themeService.isDarkMode,
              onChanged: (value) {
                themeService.toggleTheme();
              },
            ),
          ),
          const Spacer(),
          if (profile.isAdmin) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminUploadScreen(profile: profile),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm truyện mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminManageComicsScreen(profile: profile),
                  ),
                );
              },
              icon: const Icon(Icons.library_books),
              label: const Text('Quản lý truyện'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton.icon(
            onPressed: () => AuthService.instance.signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
