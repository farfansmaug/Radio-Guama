import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/category.dart';
import '../../data/repositories/wordpress_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../app/routes.dart';

/// News screen showing all categories
class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(wordpressRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.news),
      ),
      body: FutureBuilder<List<Category>>(
        future: repo.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar categorías',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(wordpressRepositoryProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final categories = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () => repo.getCategories(forceRefresh: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // "All" category card
                _CategoryCard(
                  category: null,
                  onTap: () => context.push(AppRoutes.news),
                ),
                const SizedBox(height: 12),
                
                // Category cards
                ...categories.map((category) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CategoryCard(
                    category: category,
                    onTap: () => context.push(
                      AppRoutes.newsCategory,
                      pathParameters: {'categoryId': category.id.toString()},
                    ),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Category card widget
class _CategoryCard extends StatelessWidget {
  final Category? category;
  final VoidCallback onTap;

  const _CategoryCard({
    this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category == null ? Icons.all_inclusive : Icons.folder,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? AppStrings.all,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (category != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${category.count} artículos',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// News category screen showing posts for a specific category
class NewsCategoryScreen extends ConsumerWidget {
  final int categoryId;

  const NewsCategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(wordpressRepositoryProvider);
    
    // Get category name for app bar
    String categoryName = 'Noticias';
    if (categoryId == CategoryIds.destacada) categoryName = 'Destacada';
    else if (categoryId == CategoryIds.ultimasNoticias) categoryName = 'Últimas Noticias';
    else if (categoryId == CategoryIds.deNuestrosProgramas) categoryName = 'De Nuestros Programas';
    else if (categoryId == CategoryIds.deportes) categoryName = 'Deportes';
    else if (categoryId == CategoryIds.cultura) categoryName = 'Cultura';
    else if (categoryId == CategoryIds.opinion) categoryName = 'Opinión';

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: FutureBuilder(
        future: repo.getPosts(categoryId: categoryId, perPage: 30),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar noticias',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(wordpressRepositoryProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data as List<dynamic>? ?? [];

          if (posts.isEmpty) {
            return const Center(
              child: Text('No hay noticias en esta categoría'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => repo.getPosts(categoryId: categoryId, forceRefresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: post.featuredImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.featuredImageUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.article),
                          ),
                    title: Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      post.excerpt ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.push(
                      AppRoutes.postDetail,
                      extra: {'postId': post.id},
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
