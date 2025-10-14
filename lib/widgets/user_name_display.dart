import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget hiển thị tên user realtime từ Firestore
/// Tự động cập nhật khi user đổi tên
class UserNameDisplay extends StatelessWidget {
  const UserNameDisplay({
    super.key,
    required this.userId,
    this.style,
    this.fallbackName = 'Anonymous',
  });

  final String userId;
  final TextStyle? style;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final displayName = snapshot.data!.data()?['displayName'] as String?;
          return Text(
            displayName?.isNotEmpty == true ? displayName! : fallbackName,
            style: style,
          );
        }
        return Text(fallbackName, style: style);
      },
    );
  }
}
