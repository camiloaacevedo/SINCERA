import 'package:flutter/material.dart';
import '../widgets/post_item.dart';

class PostViewScreen extends StatelessWidget {
  final List posts;
  final int initialIndex;
  final String? currentUsername;
  final bool isFollowingProfile;

  const PostViewScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
    this.currentUsername,
    this.isFollowingProfile = false,
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
          // Creamos una copia del post para no modificar la lista original directamente
          final Map<String, dynamic> postData = Map<String, dynamic>.from(
            posts[index],
          );

          // FORZAMOS el estado de seguimiento que viene del perfil
          postData['is_following'] = isFollowingProfile;

          return SingleChildScrollView(
            child: PostItem(
              post: postData, // Pasamos el post con el dato corregido
              currentUsername: currentUsername,
            ),
          );
        },
      ),
    );
  }
}
