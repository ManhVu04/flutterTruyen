import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/forum_post.dart';
import '../services/forum_service.dart';
import '../widgets/user_name_display.dart';
import '../models/user_profile.dart';

class PostDetailScreen extends StatefulWidget {
  final ForumPost post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Để track reply mode
  String? _replyToCommentId;
  String? _replyToUserId;
  String? _replyToUserName;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _setReplyMode({
    required String commentId,
    required String userId,
    required String userName,
  }) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUserId = userId;
      _replyToUserName = userName;
    });
    FocusScope.of(context).requestFocus(FocusNode()); // Focus vào input
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUserId = null;
      _replyToUserName = null;
    });
  }

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

  Future<void> _addComment() async {
    final content = _commentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập bình luận')));
      return;
    }

    try {
      debugPrint('Adding comment to post: ${widget.post.id}');
      debugPrint('Comment content: $content');
      debugPrint('User ID: $currentUserId');
      debugPrint('Reply to comment: $_replyToCommentId');

      await ForumService.addComment(
        postId: widget.post.id,
        userId: currentUserId,
        content: content,
        parentCommentId: _replyToCommentId, // Null nếu không phải reply
        replyToUserId: _replyToUserId,
      );

      _commentController.clear();
      _cancelReply(); // Clear reply mode
      FocusScope.of(context).unfocus();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thêm bình luận')));
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết')),
      body: Column(
        children: [
          // Post content (scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        StreamBuilder<UserProfile?>(
                          stream: Stream.fromFuture(
                            UserProfile.getProfile(widget.post.authorId),
                          ),
                          builder: (context, snapshot) {
                            final profile = snapshot.data;
                            final hasAvatar =
                                profile?.avatarUrl != null &&
                                profile!.avatarUrl.isNotEmpty;
                            return CircleAvatar(
                              radius: 24,
                              backgroundImage: hasAvatar
                                  ? NetworkImage(profile.avatarUrl)
                                  : null,
                              child: !hasAvatar
                                  ? const Icon(Icons.person)
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UserNameDisplay(userId: widget.post.authorId),
                              Text(
                                _formatTimestamp(widget.post.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Post content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.post.content,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Post images
                  if (widget.post.imageUrls.isNotEmpty)
                    _buildImageGrid(widget.post.imageUrls),

                  // Like & comment count
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: StreamBuilder<ForumPost>(
                      stream: _getPostUpdates(),
                      initialData: widget.post,
                      builder: (context, snapshot) {
                        final post = snapshot.data ?? widget.post;
                        final isLiked = post.likedBy.contains(currentUserId);

                        return Column(
                          children: [
                            Row(
                              children: [
                                // Like button
                                InkWell(
                                  onTap: () {
                                    ForumService.toggleLike(
                                      post.id,
                                      currentUserId,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isLiked
                                              ? Colors.red
                                              : Colors.grey[600],
                                          size: 22,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${post.likeCount} Thích',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Comment count
                                Row(
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
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const Divider(),

                  // Comments section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Bình luận',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),

                  StreamBuilder<List<ForumComment>>(
                    stream: ForumService.getComments(widget.post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Lỗi tải bình luận: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      final allComments = snapshot.data ?? [];

                      // Chỉ lấy root comments (không phải replies)
                      final rootComments = allComments
                          .where((c) => c.parentCommentId == null)
                          .toList();

                      // Debug: In ra số lượng comments
                      debugPrint('Total comments: ${allComments.length}');
                      debugPrint('Root comments: ${rootComments.length}');

                      if (rootComments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Chưa có bình luận nào',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rootComments.length,
                        itemBuilder: (context, index) {
                          final comment = rootComments[index];
                          return _CommentCard(
                            comment: comment,
                            formatTimestamp: _formatTimestamp,
                            currentUserId: currentUserId,
                            onReply: () {
                              // Get user name first
                              UserProfile.getProfile(comment.userId).then((
                                profile,
                              ) {
                                _setReplyMode(
                                  commentId: comment.id,
                                  userId: comment.userId,
                                  userName: profile?.displayName ?? 'User',
                                );
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Comment input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Reply indicator
                if (_replyToUserName != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.blue.shade50,
                    child: Row(
                      children: [
                        const Icon(Icons.reply, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Trả lời $_replyToUserName',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: _cancelReply,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                // Input row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: _replyToUserName != null
                              ? 'Viết câu trả lời...'
                              : 'Viết bình luận...',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addComment,
                      icon: const Icon(Icons.send),
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<String> imageUrls) {
    if (imageUrls.length == 1) {
      return Image.network(
        imageUrls[0],
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(imageUrls[index], fit: BoxFit.cover),
        );
      },
    );
  }

  Stream<ForumPost> _getPostUpdates() {
    return ForumService.getPosts().map(
      (posts) => posts.firstWhere(
        (p) => p.id == widget.post.id,
        orElse: () => widget.post,
      ),
    );
  }
}

class _CommentCard extends StatefulWidget {
  final ForumComment comment;
  final String Function(DateTime?) formatTimestamp;
  final String currentUserId;
  final VoidCallback onReply;

  const _CommentCard({
    required this.comment,
    required this.formatTimestamp,
    required this.currentUserId,
    required this.onReply,
  });

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main comment
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<UserProfile?>(
                stream: Stream.fromFuture(
                  UserProfile.getProfile(widget.comment.userId),
                ),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final hasAvatar =
                      profile?.avatarUrl != null &&
                      profile!.avatarUrl.isNotEmpty;
                  return CircleAvatar(
                    radius: 18,
                    backgroundImage: hasAvatar
                        ? NetworkImage(profile.avatarUrl)
                        : null,
                    child: !hasAvatar
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserNameDisplay(userId: widget.comment.userId),
                          const SizedBox(height: 4),
                          Text(widget.comment.content),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          Text(
                            widget.formatTimestamp(widget.comment.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: widget.onReply,
                            child: Text(
                              'Trả lời',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (widget.comment.replyCount > 0) ...[
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showReplies = !_showReplies;
                                });
                              },
                              child: Text(
                                _showReplies
                                    ? 'Ẩn ${widget.comment.replyCount} trả lời'
                                    : 'Xem ${widget.comment.replyCount} trả lời',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Replies
        if (_showReplies && widget.comment.replyCount > 0)
          StreamBuilder<List<ForumComment>>(
            stream: ForumService.getReplies(widget.comment.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.only(left: 60),
                  child: CircularProgressIndicator(),
                );
              }

              final replies = snapshot.data!;
              return Column(
                children: replies
                    .map(
                      (reply) => Padding(
                        padding: const EdgeInsets.only(left: 46),
                        child: _ReplyCard(
                          reply: reply,
                          formatTimestamp: widget.formatTimestamp,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}

// Reply card (tương tự comment nhưng nhỏ hơn)
class _ReplyCard extends StatelessWidget {
  final ForumComment reply;
  final String Function(DateTime?) formatTimestamp;

  const _ReplyCard({required this.reply, required this.formatTimestamp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<UserProfile?>(
            stream: Stream.fromFuture(UserProfile.getProfile(reply.userId)),
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final hasAvatar =
                  profile?.avatarUrl != null && profile!.avatarUrl.isNotEmpty;
              return CircleAvatar(
                radius: 14,
                backgroundImage: hasAvatar
                    ? NetworkImage(profile.avatarUrl)
                    : null,
                child: !hasAvatar ? const Icon(Icons.person, size: 14) : null,
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserNameDisplay(userId: reply.userId),
                      const SizedBox(height: 3),
                      Text(reply.content, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    formatTimestamp(reply.createdAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
