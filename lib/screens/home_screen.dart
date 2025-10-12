import 'package:firebase_auth/firebase_auth.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'tabs/library_tab.dart';
import 'tabs/simple_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _titles = <String>[
    'Tủ Sách',
    'Truyện',
    'Tìm kiếm',
    'Thế giới',
    'Tôi',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = <Widget>[
      LibraryTab(user: user),
      const SimpleTab(icon: Icons.menu_book, title: 'Kho truyen dang cap nhat'),
      const SimpleTab(icon: Icons.search, title: 'Tim kiem truyen'),
      const SimpleTab(icon: Icons.public, title: 'The gioi truyen'),
      _ProfileTab(user: user),
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
          TabItem(icon: Icons.search, title: 'Tìm kiếm'),
          TabItem(icon: Icons.language, title: 'Thế giới'),
          TabItem(icon: Icons.person, title: 'Tôi'),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final displayLetter = (user.displayName ?? user.email ?? 'T').isNotEmpty
        ? (user.displayName ?? user.email ?? 'T')[0].toUpperCase()
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
            user.displayName ?? 'Chua cap nhat ten',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(user.email ?? '', textAlign: TextAlign.center),
          const Spacer(),
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
