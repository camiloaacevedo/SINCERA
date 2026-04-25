import 'package:flutter/material.dart';

class SinceraUtils {
  static void verFotoGrande(BuildContext context, String? url) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.5, // El tamaño alargado que pediste
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30), // Bordes redondeados
            image: url != null && url.isNotEmpty
                ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                : null,
          ),
          child: (url == null || url.isEmpty)
              ? const Icon(Icons.person, size: 100, color: Colors.white24)
              : null,
        ),
      ),
    );
  }
}