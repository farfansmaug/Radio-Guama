import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/post.dart';
import '../../core/constants/app_constants.dart';
import '../../app/routes.dart';

/// Post card widget for displaying post previews
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push(AppRoutes.postDetail, extra: {'postId': post.id}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured image
            if (post.featuredImageUrl != null)
              CachedNetworkImage(
                imageUrl: post.featuredImageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 160,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 160,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              )
            else
              Container(
                height: 160,
                color: Colors.grey[300],
                child: const Icon(Icons.article, size: 50, color: Colors.grey),
              ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM yyyy').format(post.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  if (post.excerpt != null && post.excerpt!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      post.excerpt!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
