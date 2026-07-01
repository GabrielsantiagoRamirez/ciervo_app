import 'package:flutter/material.dart';

import '../../../profile/presentation/widgets/profile_photo_image.dart';
import '../../../../shared/widgets/ciervo_network_image.dart';
import '../../domain/entities/child_profile.dart';

class ChildProfileAvatar extends StatelessWidget {
  const ChildProfileAvatar({
    required this.child,
    this.radius = 24,
    this.onRetry,
    super.key,
  });

  final ChildProfile child;
  final double radius;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final photo = child.photoUrl?.trim();
    if (photo != null && photo.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: ClipOval(
          child: CiervoNetworkImage(
            url: photo,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            onRetry: onRetry,
            fallback: _initials(context),
          ),
        ),
      );
    }
    if (photo != null && photo.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: ClipOval(
          child: ProfilePhotoImage(
            photoRef: photo,
            width: radius * 2,
            height: radius * 2,
            fallback: _initials(context),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: _initials(context),
    );
  }

  Widget _initials(BuildContext context) {
    final parts = child.fullName.split(' ');
    final initials = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Text(
      initials.isEmpty ? '?' : initials,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}
