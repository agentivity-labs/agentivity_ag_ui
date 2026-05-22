/// Beautiful product card rendered by AgUiWidgetRegistry.
///
/// Receives props from the agent and looks up the full [ShoppingProduct]
/// definition for its gradient, badge, and feature list.
library;

import 'package:flutter/material.dart';

import '../data/products.dart';

class ShoppingProductCard extends StatelessWidget {
  const ShoppingProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  final ShoppingProduct product;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: product.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: product.gradient.first.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: emoji + badge ──────────────────────────────────
            Row(
              children: [
                Text(product.emoji,
                    style: const TextStyle(fontSize: 40)),
                const Spacer(),
                if (product.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Product name ───────────────────────────────────────────────
            Text(
              product.name,
              style: tt.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.tagline,
              style: tt.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),

            const SizedBox(height: 14),

            // ── Rating bar ─────────────────────────────────────────────────
            Row(
              children: [
                ...List.generate(5, (i) {
                  final full = i < product.rating.floor();
                  final half =
                      !full && i < product.rating && product.rating % 1 >= 0.5;
                  return Icon(
                    full
                        ? Icons.star
                        : half
                            ? Icons.star_half
                            : Icons.star_border,
                    size: 16,
                    color: Colors.amber.shade300,
                  );
                }),
                const SizedBox(width: 6),
                Text(
                  '${product.rating} (${_formatReviews(product.reviews)})',
                  style: tt.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Price + CTA ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: tt.labelSmall
                          ?.copyWith(color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    Text(
                      product.price,
                      style: tt.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _AddToCartButton(onTap: onAddToCart),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatReviews(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ── Add-to-cart button ────────────────────────────────────────────────────────

class _AddToCartButton extends StatefulWidget {
  const _AddToCartButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onTap() async {
    await _anim.forward();
    await _anim.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_shopping_cart, size: 18, color: Color(0xFF1a1a2e)),
              SizedBox(width: 6),
              Text('Add to cart',
                  style: TextStyle(
                      color: Color(0xFF1a1a2e),
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
