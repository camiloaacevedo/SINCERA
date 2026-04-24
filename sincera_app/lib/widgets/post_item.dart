import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml
import '../theme.dart';

class PostItem extends StatefulWidget {
  final Map post;
  final Function(int) onLikeUpdate; // Pasamos el nuevo total de vuelta

  const PostItem({super.key, required this.post, required this.onLikeUpdate});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  late int localLikes;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    localLikes = widget.post['likes_count'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    // Formatear fecha
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
          // CABECERA CON FECHA
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: SinceraTheme.accentNeon,
              child: Icon(Icons.person, color: Colors.black),
            ),
            title: Text(widget.post['user_id'] ?? 'User', 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Text(fecha, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ),
          
          // FOTO CON TAMAÑO CONTROLADO (No gigante)
          AspectRatio(
            aspectRatio: 1, // Foto cuadrada como Instagram
            child: Image.network(widget.post['image_url'], fit: BoxFit.cover),
          ),

          // ACCIONES Y LIKES
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
                          localLikes = isLiked ? localLikes + 1 : localLikes - 1;
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
                Text('$localLikes LIKES', 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                
                // CAJITA DE COMENTARIOS
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