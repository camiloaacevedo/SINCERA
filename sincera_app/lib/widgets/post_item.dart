import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../screens/user_profile_screen.dart';
import '../services/api_service.dart';

class PostItem extends StatefulWidget {
  final Map<String, dynamic> post;
  final Function(int)? onLikeUpdate;
  final String? currentUsername;

  const PostItem({
    super.key,
    required this.post,
    this.onLikeUpdate,
    this.currentUsername,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  final FocusNode _commentFocus = FocusNode();
  final TextEditingController _commentController = TextEditingController();
  late bool isFollowing;
  bool isWriting = false;

  @override
  void initState() {
    super.initState();
    isFollowing = widget.post['is_following'] == true;
    _commentFocus.addListener(
      () => setState(() => isWriting = _commentFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    // Cerramos el teclado al salir del post
    _commentFocus.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PostItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post['is_following'] != oldWidget.post['is_following']) {
      setState(() {
        isFollowing = widget.post['is_following'] == true;
      });
    }
  }

  Future<void> _handleFollow() async {
    if (widget.currentUsername == null || widget.post['username'] == null) {
      return;
    }

    // Guardamos el estado anterior por si la petición falla
    final bool wasFollowing = isFollowing;

    setState(() {
      isFollowing = !isFollowing;
    });

    try {
      if (wasFollowing) {
        // SI YA LO SEGUÍA, AHORA LO DEJO DE SEGUIR
        await ApiService.unfollowUser(
          widget.currentUsername!,
          widget.post['username'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Dejaste de seguir a ${widget.post['username']}"),
            ),
          );
        }
      } else {
        // SI NO LO SEGUÍA, AHORA LO SIGO
        await ApiService.followUser(
          widget.currentUsername!,
          widget.post['username'],
        );
      }
    } catch (e) {
      // Si hay error en el servidor, revertimos el botón al estado anterior
      if (mounted) {
        setState(() {
          isFollowing = wasFollowing;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Error en la conexión")));
        }
      }
    }
  }

  void _goToProfile() {
    // Cerramos teclado antes de navegar
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UserProfileScreen(username: widget.post['username']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe =
        widget.currentUsername != null &&
        widget.post['username'] != null &&
        widget.currentUsername!.trim() == widget.post['username']!.trim();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const SizedBox(width: 16),
                // CLIC SOLO EN FOTO
                GestureDetector(
                  onTap: _goToProfile,
                  child: CircleAvatar(
                    backgroundColor: SinceraTheme.accentNeon,
                    backgroundImage: widget.post['avatar_url'] != null
                        ? NetworkImage(widget.post['avatar_url'])
                        : null,
                    child: widget.post['avatar_url'] == null
                        ? const Icon(Icons.person, color: Colors.black)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // CLIC SOLO EN NOMBRE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _goToProfile,
                        child: Text(
                          widget.post['username'] ?? "usuario",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy - HH:mm').format(
                          DateTime.parse(widget.post['created_at']).toLocal(),
                        ),
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                // BOTÓN SEGUIR (Traído a la derecha)
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: _handleFollow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isFollowing
                              ? Colors.transparent
                              : SinceraTheme.accentNeon,
                          borderRadius: BorderRadius.circular(20),
                          border: isFollowing
                              ? Border.all(color: Colors.white24)
                              : null,
                        ),
                        child: Text(
                          isFollowing ? "SIGUIENDO" : "SEGUIR",
                          style: TextStyle(
                            color: isFollowing ? Colors.white54 : Colors.black,
                            // ...
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(widget.post['image_url'], fit: BoxFit.cover),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  widget.post['liked'] == true
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: widget.post['liked'] == true
                      ? Colors.red
                      : Colors.white,
                ),
                onPressed: () => widget.onLikeUpdate?.call(
                  widget.post['liked'] == true
                      ? (widget.post['likes'] - 1)
                      : (widget.post['likes'] + 1),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                ),
                onPressed: () => _commentFocus.requestFocus(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.post['likes'] ?? 0} LIKES",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    if (!isWriting && _commentController.text.isEmpty)
                      const Text(
                        "AÑADIR UN COMENTARIO...",
                        style: TextStyle(
                          color: Colors.white24,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    TextField(
                      controller: _commentController,
                      focusNode: _commentFocus,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
