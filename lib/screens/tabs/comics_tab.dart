import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import 'home_comics_tab.dart';

class ComicsTab extends StatelessWidget {
  const ComicsTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return HomeComicsTab(profile: profile);
  }
}
