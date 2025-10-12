import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key, required this.user});

  final User user;

  CollectionReference<Map<String, dynamic>> get _userCollection =>
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userCollection.doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data();
        if (data == null) {
          return const Center(child: Text('Khong tim thay ho so nguoi dung.'));
        }

        final favorites = List<String>.from(data['favorites'] ?? <String>[]);
        final readingProgress = Map<String, dynamic>.from(
          data['readingProgress'] ?? <String, dynamic>{},
        );

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                data['displayName']?.toString().isNotEmpty == true
                    ? data['displayName'].toString()
                    : (user.displayName ?? user.email ?? 'Doc gia'),
              ),
              subtitle: Text(user.email ?? ''),
              trailing: IconButton(
                onPressed: () => AuthService.instance.signOut(),
                icon: const Icon(Icons.logout),
                tooltip: 'Dang xuat',
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cap do: ${data['level'] ?? 'Luyen Khi Tang 1'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Trang thai VIP:'),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            (data['vip'] as bool? ?? false)
                                ? 'Da mo khoa'
                                : 'Chua mo',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Truyen yeu thich (${favorites.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (favorites.isEmpty)
                      const Text(
                        'Ban chua them truyen nao vao danh sach yeu thich.',
                      ),
                    for (final id in favorites)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Ma truyen: $id'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tien do doc',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (readingProgress.isEmpty)
                      const Text(
                        'Noi dung se luu khi ban doc truyen co tich hop.',
                      ),
                    for (final entry in readingProgress.entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Ma truyen: ${entry.key}'),
                        subtitle: Text(
                          'Chuong: ${entry.value['chapter'] ?? '-'} | Trang: ${entry.value['page'] ?? '-'}',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
