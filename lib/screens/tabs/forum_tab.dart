import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/forum_post.dart';
import '../../models/user_profile.dart';
import '../../services/forum_service.dart';
import '../../widgets/user_name_display.dart';
import '../create_post_screen.dart';
import '../post_detail_screen.dart';

class ForumTab extends StatefulWidget {
  final UserProfile? profile;

  const ForumTab({super.key, this.profile});

  @override
  State<ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends State<ForumTab> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thế Giới'), centerTitle: true),
      body: StreamBuilder<List<ForumPost>>(
        stream: ForumService.getPosts(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bài viết nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy là người đầu tiên chia sẻ!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              itemCount: posts.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _PostCard(
                  post: post,
                  currentUserId: currentUserId,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(post: post),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text('Đăng bài'),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ForumPost post;
  final String currentUserId;
  final VoidCallback onTap;

  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.onTap,
  });

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = post.likedBy.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Name + Time
              Row(
                children: [
                  StreamBuilder<UserProfile?>(
                    stream: Stream.fromFuture(
                      UserProfile.getProfile(post.authorId),
                    ),
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      final hasAvatar =
                          profile?.avatarUrl != null &&
                          profile!.avatarUrl.isNotEmpty;
                      return CircleAvatar(
                        radius: 20,
                        backgroundImage: hasAvatar
                            ? NetworkImage(profile.avatarUrl)
                            : null,
                        child: !hasAvatar ? const Icon(Icons.person) : null,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserNameDisplay(userId: post.authorId),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Content
              Text(post.content, style: const TextStyle(fontSize: 15)),

              // Images Grid
              if (post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildImageGrid(context, post.imageUrls),
              ],

              const SizedBox(height: 12),

              // Like & Comment buttons
              Row(
                children: [
                  // Like button
                  InkWell(
                    onTap: () {
                      ForumService.toggleLike(post.id, currentUserId);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey[600],
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.likeCount} Thích',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Comment button
                  InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            color: Colors.grey[600],
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.commentCount} Bình luận',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, List<String> imageUrls) {
    final imageCount = imageUrls.length;

    if (imageCount == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrls[0],
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
        ),
      );
    }

    if (imageCount == 2) {
      return Row(
        children: imageUrls.map((url) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url, height: 200, fit: BoxFit.cover),
              ),
            ),
          );
        }).toList(),
      );
    }

    // Grid for 3+ images
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: imageCount > 4 ? 4 : imageCount,
      itemBuilder: (context, index) {
        if (index == 3 && imageCount > 4) {
          // Show "+N more" overlay
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrls[index], fit: BoxFit.cover),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '+${imageCount - 4}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(imageUrls[index], fit: BoxFit.cover),
        );
      },
    );
  }
}
