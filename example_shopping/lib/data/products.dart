import 'package:flutter/material.dart';

@immutable
class ShoppingProduct {
  const ShoppingProduct({
    required this.id,
    required this.name,
    required this.tagline,
    required this.price,
    required this.priceValue,
    required this.emoji,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.gradient,
    this.badge,
  });

  final String id;
  final String name;
  final String tagline;
  final String price;
  final double priceValue;
  final String emoji;
  final String category;
  final double rating;
  final int reviews;
  final List<Color> gradient;
  final String? badge;
}

const kProducts = [
  ShoppingProduct(
    id: 'p1',
    name: 'ProSound Earbuds',
    tagline: '40h battery · ANC · IPX5 · Hi-Res Audio',
    price: '€69.99',
    priceValue: 69.99,
    emoji: '🎧',
    category: 'Audio',
    rating: 4.8,
    reviews: 2340,
    badge: '⭐ Top Rated',
    gradient: [Color(0xFF7B2FBE), Color(0xFF4A1880)],
  ),
  ShoppingProduct(
    id: 'p2',
    name: 'SmartTrack Pro Band',
    tagline: '14-day battery · SpO2 · GPS · Swim-proof',
    price: '€79.99',
    priceValue: 79.99,
    emoji: '⌚',
    category: 'Fitness',
    rating: 4.6,
    reviews: 1820,
    badge: '🔥 Most Popular',
    gradient: [Color(0xFF1565C0), Color(0xFF0D47A1)],
  ),
  ShoppingProduct(
    id: 'p3',
    name: 'TurboCharge 20000',
    tagline: '20,000 mAh · 65W PD · 3 ports · LED display',
    price: '€54.99',
    priceValue: 54.99,
    emoji: '⚡',
    category: 'Power',
    rating: 4.7,
    reviews: 3100,
    badge: '💰 Best Value',
    gradient: [Color(0xFF00796B), Color(0xFF004D40)],
  ),
];

ShoppingProduct? productById(String id) {
  try {
    return kProducts.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}
