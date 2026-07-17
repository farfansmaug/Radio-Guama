import 'package:flutter/material.dart';

class AppColors {
  // Primary color palette
  static const Color primary = Color(0xFF64A607);
  static const Color secondary1 = Color(0xFF76AF2A);
  static const Color secondary2 = Color(0xFF87B846);
  static const Color accent = Color(0xFFFFF2B3);

  // Additional colors
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color error = Colors.red;
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color text = Colors.black87;
  static const Color textLight = Colors.grey;
}

// Category IDs for WordPress (adjust based on actual WP setup)
class CategoryIds {
  static const int destacada = 1;
  static const int ultimasNoticias = 2;
  static const int deNuestrosProgramas = 3;
  static const int deportes = 4;
  static const int cultura = 5;
  static const int opinion = 6;
}

class AppStrings {
  static const String appName = 'Radio Guamá';
  static const String home = 'Inicio';
  static const String news = 'Noticias';
  static const String specials = 'Especiales';
  static const String podcasts = 'Podcast';
  static const String all = 'Todos';
}
