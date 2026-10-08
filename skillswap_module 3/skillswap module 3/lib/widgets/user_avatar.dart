import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String photoUrl;
  final double radius;
  const UserAvatar({super.key, required this.name, this.photoUrl = '', this.radius = 22});

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty
            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: radius * 0.8))
            : null,
      );
}
