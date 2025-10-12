import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'comic_by_genre_screen.dart';

class GenreListScreen extends StatelessWidget {
  const GenreListScreen({super.key, required this.profile});

  final UserProfile profile;

  static const List<Map<String, dynamic>> genres = [
    {
      'name': 'Cổ Đại',
      'icon': Icons.temple_buddhist,
      'color': Color(0xFF8B4513),
    },
    {
      'name': 'Hiện đại',
      'icon': Icons.location_city,
      'color': Color(0xFF2196F3),
    },
    {
      'name': 'Huyền Huyễn',
      'icon': Icons.auto_awesome,
      'color': Color(0xFF9C27B0),
    },
    {'name': 'Hai Hước', 'icon': Icons.mood, 'color': Color(0xFFFFEB3B)},
    {'name': 'Hàn Quốc', 'icon': Icons.flag, 'color': Color(0xFFE91E63)},
    {'name': 'Hậu Cung', 'icon': Icons.castle, 'color': Color(0xFFFF9800)},
    {'name': 'Hệ Thống', 'icon': Icons.computer, 'color': Color(0xFF00BCD4)},
    {'name': 'Kinh Dị', 'icon': Icons.nightlight, 'color': Color(0xFF424242)},
    {'name': 'Lịch Sử', 'icon': Icons.history_edu, 'color': Color(0xFF795548)},
    {'name': 'Mạt Thế', 'icon': Icons.warning, 'color': Color(0xFFF44336)},
    {'name': 'Ngôn Tình', 'icon': Icons.favorite, 'color': Color(0xFFE91E63)},
    {
      'name': 'Thanh xuân - Vườn trường',
      'icon': Icons.school,
      'color': Color(0xFF4CAF50),
    },
    {'name': 'Trùng Sinh', 'icon': Icons.refresh, 'color': Color(0xFF9C27B0)},
    {
      'name': 'Trong sinh',
      'icon': Icons.baby_changing_station,
      'color': Color(0xFFFF9800),
    },
    {
      'name': 'Truyện Sáng Tác',
      'icon': Icons.create,
      'color': Color(0xFF3F51B5),
    },
    {'name': 'Tu Tiên', 'icon': Icons.spa, 'color': Color(0xFF00BCD4)},
    {
      'name': 'Xuyên Không',
      'icon': Icons.flight_takeoff,
      'color': Color(0xFF9C27B0),
    },
    {'name': 'Đô Thị', 'icon': Icons.apartment, 'color': Color(0xFF607D8B)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thể Loại Truyện'), centerTitle: true),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: genres.length,
        itemBuilder: (context, index) {
          final genre = genres[index];
          return _buildGenreCard(
            context,
            genre['name'] as String,
            genre['icon'] as IconData,
            genre['color'] as Color,
          );
        },
      ),
    );
  }

  Widget _buildGenreCard(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ComicByGenreScreen(genre: name, profile: profile),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.6)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
