import 'dart:convert';
import '../constants/env.dart';
import '../models/post.dart';
import '../models/category.dart';
import '../models/comment.dart';
import '../../core/network/http_client.dart';

/// Data source for WordPress API operations
class WordPressRemoteDataSource {
  final HttpClient _httpClient = HttpClient();

  /// Fetch categories from WordPress
  Future<List<Category>> getCategories() async {
    try {
      final response = await _httpClient.get(
        '${Env.wordpressApiBase}/categories',
        queryParameters: {
          'per_page': 100,
          '_embed': true,
        },
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Category.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('[WordPressRemote] Error fetching categories: $e');
      rethrow;
    }
  }

  /// Fetch posts with optional category filter and pagination
  Future<List<Post>> getPosts({
    int? categoryId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        '_embed': true, // Include embedded media and authors
      };

      if (categoryId != null && categoryId > 0) {
        queryParams['categories'] = categoryId;
      }

      final response = await _httpClient.get(
        '${Env.wordpressApiBase}/posts',
        queryParameters: queryParams,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Post.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('[WordPressRemote] Error fetching posts: $e');
      rethrow;
    }
  }

  /// Fetch a single post by ID
  Future<Post?> getPostById(int postId) async {
    try {
      final response = await _httpClient.get(
        '${Env.wordpressApiBase}/posts/$postId',
        queryParameters: {'_embed': true},
      );

      if (response.data != null) {
        return Post.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('[WordPressRemote] Error fetching post: $e');
      rethrow;
    }
  }

  /// Fetch comments for a specific post
  Future<List<Comment>> getCommentsForPost(int postId) async {
    try {
      final response = await _httpClient.get(
        '${Env.wordpressApiBase}/comments',
        queryParameters: {
          'post': postId,
          'status': 'approve', // Only approved comments
        },
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Comment.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('[WordPressRemote] Error fetching comments: $e');
      rethrow;
    }
  }

  /// Submit a new comment to a post
  /// Note: WordPress requires authentication for posting comments via API
  /// This is a basic implementation; you may need to add auth tokens
  Future<Comment?> submitComment(Comment comment) async {
    try {
      final response = await _httpClient.post(
        '${Env.wordpressApiBase}/comments',
        data: comment.toSubmissionJson(comment.postId),
        options: Options(
          headers: {
            // Add authentication if required
            // 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data != null) {
        return Comment.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('[WordPressRemote] Error submitting comment: $e');
      rethrow;
    }
  }

  /// Search posts by keyword
  Future<List<Post>> searchPosts(String query) async {
    try {
      final response = await _httpClient.get(
        '${Env.wordpressApiBase}/posts',
        queryParameters: {
          'search': query,
          'per_page': 20,
          '_embed': true,
        },
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Post.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('[WordPressRemote] Error searching posts: $e');
      rethrow;
    }
  }
}
