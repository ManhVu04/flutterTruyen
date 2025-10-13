import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class ComicRatingWidget extends StatefulWidget {
  const ComicRatingWidget({
    super.key,
    required this.comicId,
    required this.userId,
    required this.onRated,
  });

  final String comicId;
  final String userId;
  final VoidCallback onRated;

  @override
  State<ComicRatingWidget> createState() => _ComicRatingWidgetState();
}

class _ComicRatingWidgetState extends State<ComicRatingWidget> {
  int? _userRating;
  int? _hoverRating;
  bool _isLoading = false;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadRating();
    _loadStats();
  }

  Future<void> _loadRating() async {
    try {
      final rating = await FirestoreService.instance.getUserRating(
        comicId: widget.comicId,
        userId: widget.userId,
      );
      if (mounted) {
        setState(() => _userRating = rating?.score);
      }
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await FirestoreService.instance.getComicRatingStats(
        widget.comicId,
      );
      if (mounted) {
        setState(() => _stats = stats);
      }
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _submitRating(int score) async {
    setState(() => _isLoading = true);

    try {
      await FirestoreService.instance.rateComic(
        comicId: widget.comicId,
        userId: widget.userId,
        score: score,
      );

      setState(() => _userRating = score);
      await _loadStats();
      widget.onRated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Average rating
            if (_stats != null) ...[
              Row(
                children: [
                  Text(
                    _stats!['average'].toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < _stats!['average'].round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_stats!['total']} đánh giá',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Rating distribution
              ..._buildDistribution(),
              const Divider(height: 32),
            ],
            // User rating
            Text(
              _userRating == null
                  ? 'Bạn chưa đánh giá truyện này'
                  : 'Đánh giá của bạn',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final score = index + 1;
                  final isFilled = score <= (_hoverRating ?? _userRating ?? 0);
                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoverRating = score),
                    onExit: (_) => setState(() => _hoverRating = null),
                    child: GestureDetector(
                      onTap: () => _submitRating(score),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          isFilled ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            if (_userRating != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Bạn đã đánh giá: $_userRating sao',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDistribution() {
    if (_stats == null) return [];

    final distribution = _stats!['distribution'] as Map<int, int>;
    final total = _stats!['total'] as int;

    return List.generate(5, (index) {
      final star = 5 - index;
      final count = distribution[star] ?? 0;
      final percentage = total > 0 ? (count / total) : 0.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text('$star'),
            const SizedBox(width: 4),
            const Icon(Icons.star, size: 16, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                '$count',
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    });
  }
}
