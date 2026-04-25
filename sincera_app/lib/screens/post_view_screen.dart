import 'package:flutter/material.dart';
import '../widgets/post_item.dart';

class PostViewScreen extends StatefulWidget {
  final List posts;
  final int initialIndex;
  final Function(dynamic)? onLike;

  const PostViewScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
    this.onLike,
  });

  @override
  State<PostViewScreen> createState() => _PostViewScreenState();
}

class _PostViewScreenState extends State<PostViewScreen> {
  @override
  Widget build(BuildContext context) {
    PageController controller = PageController(initialPage: widget.initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: controller,
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          return SingleChildScrollView(
            child: PostItem(
              // Pasamos el post actual de la lista
              post: widget.posts[index],
              onLikeUpdate: (nuevoTotal) {
                setState(() {
                  // Actualizamos el estado local de la lista para que al volver 
                  // al perfil o deslizar se mantenga el cambio
                  widget.posts[index]['likes_count'] = nuevoTotal;
                  widget.posts[index]['user_has_liked'] = ! (widget.posts[index]['user_has_liked'] ?? false);
                });
                
                // Enviamos al backend
                if (widget.onLike != null) {
                  widget.onLike!(widget.posts[index]['id']);
                }
              },
            ),
          );
        },
      ),
    );
  }
}