import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/env.dart';
import '../../data/models/post.dart';
import '../../data/repositories/wordpress_repository.dart';
import '../../data/repositories/ivoox_repository.dart';
import '../widgets/persistent_audio_fab.dart';
import '../widgets/post_card.dart';

/// Home screen with featured content and category sections
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  
  // Category IDs for home sections
  final List<Map<String, dynamic>> _sections = [
    {'name': AppStrings.home, 'categoryId': null},
    {'name': AppStrings.news, 'categoryId': null},
    {'name': AppStrings.specials, 'categoryId': null},
    {'name': AppStrings.podcasts, 'categoryId': null},
  ];

  // Cache image provider to avoid recreation
  late final ImageProvider _logoImage;

  @override
  void initState() {
    super.initState();
    _logoImage = const AssetImage('assets/images/logo.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: _logoImage,
              height: 40,
              width: 40,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.radio, color: Colors.white),
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(AppStrings.appName),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const NewsScreen(),
          const Center(child: Text('Especiales')), // Placeholder
          const PodcastsScreen(),
        ],
      ),
      floatingActionButton: const PersistentAudioFAB(),
      bottomNavigationBar: CurvedBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(wordpressRepositoryProvider);
        ref.invalidate(ivooxRepositoryProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured post section
            _FeaturedSection(),
            
            // Latest news
            _SectionHeader(
              title: 'Últimas Noticias',
              onSeeAll: () => context.push(AppRoutes.news),
            ),
            _LatestPostsSection(categoryId: null, limit: 3),
            
            // Programs section
            _SectionHeader(
              title: 'De Nuestros Programas',
              categoryId: CategoryIds.deNuestrosProgramas,
            ),
            _LatestPostsSection(
              categoryId: CategoryIds.deNuestrosProgramas,
              limit: 3,
            ),
            
            // Sports section
            _SectionHeader(
              title: 'Deportes',
              categoryId: CategoryIds.deportes,
            ),
            _LatestPostsSection(
              categoryId: CategoryIds.deportes,
              limit: 3,
            ),
            
            // Culture section
            _SectionHeader(
              title: 'Cultura',
              categoryId: CategoryIds.cultura,
            ),
            _LatestPostsSection(
              categoryId: CategoryIds.cultura,
              limit: 3,
            ),
            
            // Opinion section
            _SectionHeader(
              title: 'Opinión',
              categoryId: CategoryIds.opinion,
            ),
            _LatestPostsSection(
              categoryId: CategoryIds.opinion,
              limit: 3,
            ),
            
            const SizedBox(height: 80), // Space for FAB and bottom nav
          ],
        ),
      ),
    );
  }
}

/// Featured post card at the top of home
class _FeaturedSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FeaturedSection> createState() => _FeaturedSectionState();
}

class _FeaturedSectionState extends ConsumerState<_FeaturedSection> {
  // Cache for the future to avoid recreating it on every build
  late final Future<List<Post>> _featuredPostsFuture;

  @override
  void initState() {
    super.initState();
    _featuredPostsFuture = ref
        .read(wordpressRepositoryProvider)
        .getPosts(categoryId: CategoryIds.destacada, perPage: 1);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _featuredPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ShimmerFeatured();
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final post = snapshot.data!.first;
        
        return GestureDetector(
          onTap: () => context.push(AppRoutes.postDetail, extra: {'postId': post.id}),
          child: Card(
            margin: const EdgeInsets.all(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.featuredImageUrl != null)
                  CachedNetworkImage(
                    imageUrl: post.featuredImageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DESTACADO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('dd MMM yyyy').format(post.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      if (post.excerpt != null && post.excerpt!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          post.excerpt!,
                          style: Theme.of(context).textTheme.bodyMedium,
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
      },
    );
  }
}

/// Shimmer loading placeholder for featured section
class _ShimmerFeatured extends StatelessWidget {
  const _ShimmerFeatured();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Container(
        height: 300,
        color: Colors.grey[300],
      ),
    );
  }
}

/// Section header with optional "See All" button
class _SectionHeader extends StatelessWidget {
  final String title;
  final int? categoryId;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    this.categoryId,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('Ver todo'),
            )
          else if (categoryId != null)
            TextButton(
              onPressed: () => context.push(
                AppRoutes.newsCategory,
                pathParameters: {'categoryId': categoryId.toString()},
              ),
              child: const Text('Ver todo'),
            ),
        ],
      ),
    );
  }
}

/// Latest posts section for a specific category
class _LatestPostsSection extends ConsumerStatefulWidget {
  final int? categoryId;
  final int limit;

  const _LatestPostsSection({this.categoryId, this.limit = 3});

  @override
  ConsumerState<_LatestPostsSection> createState() => _LatestPostsSectionState();
}

class _LatestPostsSectionState extends ConsumerState<_LatestPostsSection> {
  // Cache for the future to avoid recreating it on every build
  late final Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = ref
        .read(wordpressRepositoryProvider)
        .getPosts(categoryId: widget.categoryId, perPage: widget.limit);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ShimmerPostList();
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No hay contenido disponible',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          );
        }
        
        final posts = snapshot.data!;
        
        return SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return SizedBox(
                width: 280,
                child: PostCard(post: post),
              );
            },
          ),
        );
      },
    );
  }
}

/// Shimmer loading placeholder for post list
class _ShimmerPostList extends StatelessWidget {
  const _ShimmerPostList();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return SizedBox(
            width: 280,
            child: Card(
              margin: const EdgeInsets.only(right: 16),
              child: Container(
                color: Colors.grey[300],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Curved bottom navigation bar
class CurvedBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CurvedBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home,
                label: AppStrings.home,
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.newspaper,
                label: AppStrings.news,
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.star,
                label: AppStrings.specials,
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.podcast,
                label: AppStrings.podcasts,
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
