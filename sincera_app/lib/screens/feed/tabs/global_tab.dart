import 'package:flutter/material.dart';
import '../widgets/feed_list_view.dart';

class GlobalTab extends StatelessWidget {
  final List posts;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final String? currentUsername;
  final Function(int, int) onPostUpdate;

  const GlobalTab({
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
      storageKey: 'global_scroll',
      posts: posts,
      isLoading: isLoading,
      onRefresh: onRefresh,
      currentUsername: currentUsername,
      onPostUpdate: onPostUpdate,
    );
  }
}
