import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'admin_manage_comics_screen.dart';
import 'admin_upload_screen.dart';
import 'edit_profile_screen.dart';
import 'tabs/library_tab.dart';
import 'tabs/forum_tab.dart';
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

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Sử dụng profile mới từ stream hoặc profile ban đầu
        final currentProfile = snapshot.hasData && snapshot.data!.exists
            ? UserProfile.fromDoc(snapshot.data!)
            : widget.profile;

        final pages = <Widget>[
          LibraryTab(user: user, profile: currentProfile),
          ComicsTab(profile: currentProfile),
          SearchTab(profile: currentProfile),
          ForumTab(profile: currentProfile),
          _ProfileTab(
            user: user,
            profile: currentProfile,
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
      },
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Background Image Header
          Stack(
            children: [
              // Background
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  image: profile.backgroundUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(profile.backgroundUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile.backgroundUrl.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.wallpaper,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      )
                    : null,
              ),
              // Edit Button
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(profile: profile),
                      ),
                    );
                  },
                  child: const Icon(Icons.edit),
                ),
              ),
              // Avatar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profile.avatarUrl.isNotEmpty
                          ? NetworkImage(profile.avatarUrl)
                          : null,
                      child: profile.avatarUrl.isEmpty
                          ? Text(
                              displayLetter,
                              style: Theme.of(context).textTheme.headlineMedium,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName
                      : (user.displayName ?? 'Chưa cập nhật tên'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? profile.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Chip(label: Text('VIP Level ${profile.vipLevel}')),
                const SizedBox(height: 24),
                // Dark Mode Toggle
                Card(
                  child: SwitchListTile(
                    title: const Text('Chế độ nền tối'),
                    subtitle: const Text('Bật/tắt giao diện tối'),
                    secondary: Icon(
                      themeService.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                    value: themeService.isDarkMode,
                    onChanged: (value) {
                      themeService.toggleTheme();
                    },
                  ),
                ),
                const SizedBox(height: 24),
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
                          builder: (_) =>
                              AdminManageComicsScreen(profile: profile),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
