import 'package:flutter/material.dart';
import '../widgets/post_item.dart';

class PostViewScreen extends StatelessWidget {
  final List posts;
  final int initialIndex;

  const PostViewScreen({super.key, required this.posts, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    PageController controller = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: PageView.builder(
        controller: controller,
        itemCount: posts.length,
        scrollDirection: Axis.horizontal, // Deslizar lateral
        itemBuilder: (context, index) {
          return SingleChildScrollView(
            child: PostItem(
              post: posts[index],
              onLikeUpdate: (n) => posts[index]['likes_count'] = n,
            ),
          );
        },
      ),
    );
  }
}