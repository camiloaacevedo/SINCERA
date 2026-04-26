import 'package:flutter/material.dart';
import '../widgets/feed_list_view.dart';

class FollowingTab extends StatelessWidget {
  final List posts;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final String? currentUsername;
  final Function(int, int) onPostUpdate;

  const FollowingTab({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.onRefresh,
    this.currentUsername,
    required this.onPostUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return FeedListView(
      storageKey: 'following_scroll',
      posts: posts,
      isLoading: isLoading,
      onRefresh: onRefresh,
      currentUsername: currentUsername,
      onPostUpdate: onPostUpdate,
    );
  }
}
