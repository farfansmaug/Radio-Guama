import '../models/post.dart';
import '../models/category.dart';
import '../models/comment.dart';
import '../datasources/wordpress_remote_datasource.dart';
import '../../core/storage/storage_helper.dart';

/// Repository for WordPress data (posts, categories, comments)
/// Handles both remote fetching and local caching
class WordPressRepository {
  final WordPressRemoteDataSource _remoteDataSource = WordPressRemoteDataSource();
  final StorageHelper _storage = StorageHelper();

  /// Get all categories (with caching)
  Future<List<Category>> getCategories({bool forceRefresh = false}) async {
    // Try cache first
    if (!forceRefresh) {
      final cachedCategories = _getCachedCategories();
      if (cachedCategories.isNotEmpty) {
        return cachedCategories;
      }
    }

    // Fetch from remote
    try {
      final categories = await _remoteDataSource.getCategories();
      await _cacheCategories(categories);
      return categories;
    } catch (e) {
      print('[WordPressRepo] Error getting categories: $e');
      // Return cached data even if stale on error
      return _getCachedCategories();
    }
  }

  /// Get posts with optional category filter (with caching)
  Future<List<Post>> getPosts({
    int? categoryId,
    int page = 1,
    int perPage = 20,
    bool forceRefresh = false,
  }) async {
    // Generate cache key based on parameters
    final cacheKey = categoryId != null ? 'posts_cat_$categoryId' : 'posts_all';
    
    // Try cache first for non-first page requests
    if (!forceRefresh && page == 1) {
      final cachedPosts = _getCachedPosts(categoryId: categoryId);
      if (cachedPosts.isNotEmpty) {
        return cachedPosts;
      }
    }

    // Fetch from remote
    try {
      final posts = await _remoteDataSource.getPosts(
        categoryId: categoryId,
        page: page,
        perPage: perPage,
      );
      
      // Cache only first page results
      if (page == 1) {
        await _cachePosts(posts, categoryId: categoryId);
      }
      
      return posts;
    } catch (e) {
      print('[WordPressRepo] Error getting posts: $e');
      // Return cached data even if stale on error
      return _getCachedPosts(categoryId: categoryId);
    }
  }

  /// Get a single post by ID
  Future<Post?> getPostById(int postId) async {
    try {
      return await _remoteDataSource.getPostById(postId);
    } catch (e) {
      print('[WordPressRepo] Error getting post by ID: $e');
      return null;
    }
  }

  /// Get comments for a post
  Future<List<Comment>> getCommentsForPost(int postId) async {
    try {
      return await _remoteDataSource.getCommentsForPost(postId);
    } catch (e) {
      print('[WordPressRepo] Error getting comments: $e');
      return [];
    }
  }

  /// Submit a comment
  Future<Comment?> submitComment(Comment comment) async {
    try {
      final submittedComment = await _remoteDataSource.submitComment(comment);
      if (submittedComment != null) {
        await _cacheComment(submittedComment);
      }
      return submittedComment;
    } catch (e) {
      print('[WordPressRepo] Error submitting comment: $e');
      return null;
    }
  }

  /// Search posts
  Future<List<Post>> searchPosts(String query) async {
    try {
      return await _remoteDataSource.searchPosts(query);
    } catch (e) {
      print('[WordPressRepo] Error searching posts: $e');
      return [];
    }
  }

  // ==================== CACHING METHODS ====================

  List<Category> _getCachedCategories() {
    try {
      final box = _storage.categoriesBox;
      final categories = <Category>[];
      for (final key in box.keys) {
        final data = box.get(key);
        if (data is Map<String, dynamic>) {
          categories.add(Category.fromJson(data));
        }
      }
      return categories;
    } catch (e) {
      print('[WordPressRepo] Error reading cached categories: $e');
      return [];
    }
  }

  Future<void> _cacheCategories(List<Category> categories) async {
    try {
      final box = _storage.categoriesBox;
      await box.clear();
      for (final category in categories) {
        await box.put(category.id, category.toJson());
      }
    } catch (e) {
      print('[WordPressRepo] Error caching categories: $e');
    }
  }

  List<Post> _getCachedPosts({int? categoryId}) {
    try {
      final box = _storage.postsBox;
      final posts = <Post>[];
      
      for (final key in box.keys) {
        final data = box.get(key);
        if (data is Map<String, dynamic>) {
          final post = Post.fromJson(data);
          // Filter by category if specified
          if (categoryId == null || post.categories.contains(categoryId)) {
            posts.add(post);
          }
        }
      }
      
      // Sort by date (newest first)
      posts.sort((a, b) => b.date.compareTo(a.date));
      return posts;
    } catch (e) {
      print('[WordPressRepo] Error reading cached posts: $e');
      return [];
    }
  }

  Future<void> _cachePosts(List<Post> posts, {int? categoryId}) async {
    try {
      final box = _storage.postsBox;
      for (final post in posts) {
        await box.put(post.id, post.toJson());
      }
    } catch (e) {
      print('[WordPressRepo] Error caching posts: $e');
    }
  }

  Future<void> _cacheComment(Comment comment) async {
    try {
      final box = _storage.commentsBox;
      await box.put(comment.id, comment.toJson());
    } catch (e) {
      print('[WordPressRepo] Error caching comment: $e');
    }
  }

  /// Clear all cached WordPress data
  Future<void> clearCache() async {
    await _storage.postsBox.clear();
    await _storage.categoriesBox.clear();
    await _storage.commentsBox.clear();
  }
}
