import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 用户头像组件
class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: colorScheme.primaryContainer,
        child: imageUrl.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Icon(
                    Icons.person,
                    size: size * 0.5,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  errorWidget: (_, _, _) => Icon(
                    Icons.person,
                    size: size * 0.5,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              )
            : Icon(
                Icons.person,
                size: size * 0.5,
                color: colorScheme.onPrimaryContainer,
              ),
      ),
    );
  }
}
