import 'package:flutter/material.dart';
import '../widgets/post_item.dart';

class PostViewScreen extends StatelessWidget {
  final List posts;
  final int initialIndex;
  final String? currentUsername;

  const PostViewScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
    this.currentUsername,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return SingleChildScrollView(
            child: PostItem(
              post: posts[index],
              currentUsername:
                  currentUsername,
            ),
          );
        },
      ),
    );
  }
}
