import 'package:flutter/material.dart';
import '../../../widgets/post_item.dart';
import '../../../theme.dart';

class FeedListView extends StatefulWidget {
  final List posts;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final String? currentUsername;
  final Function(int, int) onPostUpdate;
  final String storageKey;

  const FeedListView({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.onRefresh,
    required this.onPostUpdate,
    required this.storageKey,
    this.currentUsername,
  });

  @override
  State<FeedListView> createState() => _FeedListViewState();
}

class _FeedListViewState extends State<FeedListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Esto evita que la pestaña se destruya

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: SinceraTheme.accentNeon),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        // La clave mágica que guarda la posición del scroll
        key: PageStorageKey(widget.storageKey),
        itemCount: widget.posts.length,
        itemBuilder: (context, i) => PostItem(
          post: widget.posts[i],
          currentUsername: widget.currentUsername,
          onLikeUpdate: (n) => widget.onPostUpdate(i, n),
        ),
      ),
    );
  }
}
