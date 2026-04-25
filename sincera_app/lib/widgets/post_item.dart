import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../screens/user_profile_screen.dart';

class PostItem extends StatefulWidget {
  final Map post;
  final Function(int) onLikeUpdate;

  const PostItem({super.key, required this.post, required this.onLikeUpdate});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  late int localLikes;
  bool isLiked = false;
  late bool isFollowing; // Cambiado a late para asegurar inicialización
  String? currentUsername;

  @override
  void initState() {
    super.initState();
    localLikes = widget.post['likes_count'] ?? 0;
    isFollowing = widget.post['already_following'] ?? false;
    // Cargar el estado del like desde el backend
    isLiked = widget.post['user_has_liked'] ?? false;
    _loadUser();
  }

  @override
  void didUpdateWidget(PostItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Comparamos si los datos del post que llegan son diferentes a los anteriores
    if (oldWidget.post['likes_count'] != widget.post['likes_count'] ||
        oldWidget.post['user_has_liked'] != widget.post['user_has_liked']) {
      setState(() {
        // Actualizamos el estado local con los nuevos datos del servidor
        localLikes = widget.post['likes_count'] ?? 0;
        isLiked = widget.post['user_has_liked'] ?? false;
        isFollowing = widget.post['already_following'] ?? false;
      });
    }
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUsername = prefs.getString('username');
    });
  }

  Future<void> _handleFollow() async {
    if (currentUsername == null) return;
    await ApiService.followUser(currentUsername!, widget.post['user_id']);
  }

  @override
  Widget build(BuildContext context) {
    String fecha = "";
    if (widget.post['created_at'] != null) {
      DateTime dt = DateTime.parse(widget.post['created_at']);
      fecha = DateFormat('dd MMM, HH:mm').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UserProfileScreen(username: widget.post['user_id']),
                  ),
                );
              },
              child: const CircleAvatar(
                backgroundColor: SinceraTheme.accentNeon,
                child: Icon(Icons.person, color: Colors.black),
              ),
            ),
            title: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UserProfileScreen(username: widget.post['user_id']),
                  ),
                );
              },
              child: Text(
                widget.post['user_id'] ?? 'User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            subtitle: Text(
              fecha,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            // LÓGICA DE BOTÓN DINÁMICA
            trailing: (currentUsername == widget.post['user_id'])
                ? null
                : isFollowing
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      "SIGUIENDO",
                      style: TextStyle(
                        color: Colors
                            .white24, // Color más tenue para el estado pasivo
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: () {
                      setState(() {
                        isFollowing = true;
                      });
                      _handleFollow();
                    },
                    child: const Text(
                      "SEGUIR",
                      style: TextStyle(
                        color: SinceraTheme.accentNeon,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),

          AspectRatio(
            aspectRatio: 1,
            child: Image.network(widget.post['image_url'], fit: BoxFit.cover),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isLiked = !isLiked;
                          localLikes = isLiked
                              ? localLikes + 1
                              : localLikes - 1;
                        });
                        widget.onLikeUpdate(localLikes);
                      },
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$localLikes LIKES',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const TextField(
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Escribe un comentario...",
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
