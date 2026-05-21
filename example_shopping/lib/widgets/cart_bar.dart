/// Persistent animated cart bar shown at the bottom of the screen.
library;

import 'package:flutter/material.dart';

class CartBar extends StatefulWidget {
  const CartBar({
    super.key,
    required this.itemCount,
    required this.total,
  });

  final int itemCount;
  final double total;

  @override
  State<CartBar> createState() => _CartBarState();
}

class _CartBarState extends State<CartBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double> _scale;
  int _prevCount = 0;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.94), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(CartBar old) {
    super.didUpdateWidget(old);
    if (widget.itemCount != _prevCount && widget.itemCount > _prevCount) {
      _bounce
        ..reset()
        ..forward();
    }
    _prevCount = widget.itemCount;
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.itemCount == 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: isEmpty ? 56 : 68,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1E3A), Color(0xFF12122A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          top: BorderSide(color: Color(0xFF3D3D6B), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // ── Cart icon with badge ──────────────────────────────────────
            ScaleTransition(
              scale: _scale,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: isEmpty
                        ? Colors.white38
                        : const Color(0xFF7C4DFF),
                    size: 26,
                  ),
                  if (!isEmpty)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C4DFF),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        child: Text(
                          '${widget.itemCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // ── Label ─────────────────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isEmpty
                    ? const Text(
                        'Your cart is empty',
                        key: ValueKey('empty'),
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 14),
                      )
                    : Column(
                        key: const ValueKey('full'),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.itemCount} item${widget.itemCount > 1 ? 's' : ''} in cart',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11),
                          ),
                          Text(
                            '€${widget.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),

            // ── Checkout button ───────────────────────────────────────────
            AnimatedOpacity(
              opacity: isEmpty ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: isEmpty ? const Offset(1, 0) : Offset.zero,
                curve: Curves.easeOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Checkout →',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
