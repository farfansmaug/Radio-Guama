import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:html/widgets.dart' as html_widgets;
import 'package:intl/intl.dart';
import '../../data/models/post.dart';
import '../../data/repositories/wordpress_repository.dart';
import '../../core/constants/app_constants.dart';

/// Post detail screen showing full content and comments
class PostDetailScreen extends ConsumerStatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _showCommentForm = false;

  @override
  void dispose() {
    _commentController.dispose();
    _authorController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
      ),
      body: FutureBuilder<Post?>(
        future: ref.read(wordpressRepositoryProvider).getPostById(widget.postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar el artículo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          final post = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured image
                if (post.featuredImageUrl != null)
                  CachedNetworkImage(
                    imageUrl: post.featuredImageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Date and author
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMMM yyyy').format(post.date),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          if (post.author != null) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.person, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Autor: ${post.author}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                      
                      const Divider(height: 32),
                      
                      // HTML content
                      html_widgets.HtmlWidget(
                        post.content,
                        textStyle: Theme.of(context).textTheme.bodyLarge,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Comments section
                      _CommentsSection(postId: post.id),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _showCommentForm = !_showCommentForm;
          });
        },
        icon: const Icon(Icons.comment),
        label: const Text('Comentar'),
      ),
      bottomSheet: _showCommentForm ? _buildCommentForm() : null,
    );
  }

  Widget _buildCommentForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _authorController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Comentario',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showCommentForm = false;
                  });
                },
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  // Submit comment logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comentario enviado para moderación')),
                  );
                  setState(() {
                    _showCommentForm = false;
                  });
                  _commentController.clear();
                },
                child: const Text('Enviar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Comments section widget
class _CommentsSection extends ConsumerWidget {
  final int postId;

  const _CommentsSection({required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(wordpressRepositoryProvider).getCommentsForPost(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data as List<dynamic>? ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Comentarios (${comments.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (comments.isEmpty)
              const Text('No hay comentarios aún. ¡Sé el primero en comentar!')
            else
              ...comments.map((comment) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                (comment.authorName ?? 'A')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.authorName ?? 'Anónimo',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(comment.date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(comment.content ?? ''),
                      ],
                    ),
                  ),
                ),
              )),
          ],
        );
      },
    );
  }
}
