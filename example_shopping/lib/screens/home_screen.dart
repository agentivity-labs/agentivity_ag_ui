/// AI Shopping Assistant home screen.
///
/// Demonstrates the full AG-UI feature set in a polished dark-themed UI:
///   • Stream runs on a broadcast channel → 4 controllers in parallel
///   • Reasoning block, tool call cards, streaming text
///   • Product cards rendered via AgUiWidgetRegistry
///   • Activity indicator with animated progress
///   • State-synced cart bar at the bottom
///   • Human-in-the-loop bottom sheet for product selection
library;

import 'dart:async';

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';

import '../data/demo_stream.dart';
import '../data/products.dart';
import '../widgets/cart_bar.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Controllers ─────────────────────────────────────────────────────────────
  AgUiRunLifecycleController? _lifecycle;
  AgUiActivityController? _activity;
  AgUiStateController? _stateCtrl;
  AgUiGenerativeController? _genCtrl;

  // ── Cart state (mirrored from AgUiStateController for quick reads) ──────────
  int _cartItems = 0;
  double _cartTotal = 0.0;

  // ── UI state ─────────────────────────────────────────────────────────────────
  bool _running = false;
  bool _waitingForPick = false;
  bool _done = false;

  // ── Widget registry ──────────────────────────────────────────────────────────
  // Built lazily so it can close over _onAddToCart
  late final AgUiWidgetRegistry _registry = AgUiWidgetRegistry({
    'ProductCard': (_, props) {
      final id = jsonStr(props, 'id');
      final product = productById(id);
      if (product == null) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Unknown product: $id',
              style: const TextStyle(color: Colors.red)),
        );
      }
      return ShoppingProductCard(
        product: product,
        onAddToCart: () => _onAddToCart(product),
      );
    },
  });

  @override
  void initState() {
    super.initState();
    // Auto-play on open after a brief delay
    Future.delayed(const Duration(milliseconds: 600), _startDemo);
  }

  // ── Demo lifecycle ────────────────────────────────────────────────────────────

  void _startDemo() {
    _disposeAll();
    final broadcast = buildDemoStream().asBroadcastStream();

    final lifecycle = AgUiRunLifecycleController(events: broadcast);
    final activity = AgUiActivityController(events: broadcast);
    final stateCtrl = AgUiStateController(events: broadcast);
    final genCtrl = AgUiGenerativeController(
        events: broadcast, widgetRegistry: _registry);

    lifecycle.addListener(() => _onLifecycle(lifecycle));
    activity.addListener(() {
      if (mounted) setState(() {});
    });
    stateCtrl.addListener(() {
      if (!mounted) return;
      final s = stateCtrl.state;
      setState(() {
        _cartItems = (s['itemCount'] as num?)?.toInt() ?? 0;
        _cartTotal = (s['total'] as num?)?.toDouble() ?? 0.0;
      });
    });
    genCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    setState(() {
      _lifecycle = lifecycle;
      _activity = activity;
      _stateCtrl = stateCtrl;
      _genCtrl = genCtrl;
      _running = true;
      _waitingForPick = false;
      _done = false;
      _cartItems = 0;
      _cartTotal = 0.0;
    });
  }

  void _onLifecycle(AgUiRunLifecycleController lc) {
    if (!mounted) return;
    if (lc.isInterrupted) {
      setState(() {
        _running = false;
        _waitingForPick = true;
      });
      // Small delay so user can read the message first
      Future.delayed(const Duration(milliseconds: 600),
          () => _showProductPicker());
    } else if (lc.isFinished) {
      setState(() {
        _running = false;
        _done = true;
      });
    } else {
      setState(() {});
    }
  }

  void _onAddToCart(ShoppingProduct product) {
    // Direct add (when tapping card button while not waiting for HIL)
    _showProductPicker(preSelected: product);
  }

  void _showProductPicker({ShoppingProduct? preSelected}) {
    if (!mounted) return;
    showModalBottomSheet<ShoppingProduct>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ProductPickerSheet(
        products: kProducts,
        preSelected: preSelected,
      ),
    ).then((picked) {
      if (picked == null) return;
      _resumeWithProduct(picked);
    });
  }

  void _resumeWithProduct(ShoppingProduct product) {
    // Dispose everything cleanly (nulls fields first — see _disposeAll).
    _disposeAll();

    setState(() {
      _waitingForPick = false;
      _running = true;
      _done = false;
    });

    final resumeBroadcast = buildResumeStream(
      productId: product.id,
      productName: product.name,
      price: product.price,
      priceValue: product.priceValue,
    ).asBroadcastStream();

    final lifecycle = AgUiRunLifecycleController(events: resumeBroadcast);
    final stateCtrl = AgUiStateController(events: resumeBroadcast);
    final genCtrl = AgUiGenerativeController(
        events: resumeBroadcast, widgetRegistry: _registry);

    lifecycle.addListener(() {
      if (!mounted) return;
      if (lifecycle.isFinished) setState(() { _running = false; _done = true; });
    });
    stateCtrl.addListener(() {
      if (!mounted) return;
      final s = stateCtrl.state;
      if (s.isNotEmpty) {
        setState(() {
          _cartItems = (s['itemCount'] as num?)?.toInt() ?? _cartItems;
          _cartTotal = (s['total'] as num?)?.toDouble() ?? _cartTotal;
        });
      }
    });
    genCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    setState(() {
      _lifecycle = lifecycle;
      _stateCtrl = stateCtrl;
      _genCtrl = genCtrl;
    });
  }

  void _disposeAll() {
    // Null the fields FIRST so any in-progress setState rebuild sees null
    // and removes the widget from the tree before dispose() is called.
    // This prevents ListenableBuilder.didUpdateWidget from calling
    // removeListener() on an already-disposed ChangeNotifier.
    final lc = _lifecycle;
    final ac = _activity;
    final sc = _stateCtrl;
    final gc = _genCtrl;
    _lifecycle = null;
    _activity = null;
    _stateCtrl = null;
    _genCtrl = null;
    lc?.dispose();
    ac?.dispose();
    sc?.dispose();
    gc?.dispose();
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Read current activity directly — we already call setState() from the
    // activity listener, so no ListenableBuilder needed here. Using one would
    // hold a widget-State reference to the controller and crash when the
    // controller is disposed while the widget is still in the tree.
    final currentActivity = _activity?.current;
    final genCtrl = _genCtrl;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Activity bar ───────────────────────────────────────────────────
          if (currentActivity != null)
            _ActivityBar(activity: currentActivity),

          // ── Main content ───────────────────────────────────────────────────
          Expanded(
            child: genCtrl == null
                ? _buildSplash()
                : AgUiGenerativeView(
                    controller: genCtrl,
                    registry: _registry,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    emptyBuilder: (_) => _buildSplash(),
                  ),
          ),

          // ── Waiting for pick label ─────────────────────────────────────────
          if (_waitingForPick)
            _PickPromptBanner(
              onTap: _showProductPicker,
            ),

          // ── Cart bar ───────────────────────────────────────────────────────
          CartBar(itemCount: _cartItems, total: _cartTotal),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            bottom: BorderSide(color: Color(0xFF2D2D5E), width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Logo + title
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Color(0xFF7C4DFF), size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('AI Shopping',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _running
                                ? Colors.green
                                : _waitingForPick
                                    ? Colors.orange
                                    : _done
                                        ? Colors.blue
                                        : Colors.white30,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _running
                              ? 'Thinking…'
                              : _waitingForPick
                                  ? 'Waiting for your choice'
                                  : _done
                                      ? 'Done'
                                      : 'Ready',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Replay button when done
                if (_done || (!_running && _genCtrl != null))
                  IconButton(
                    onPressed: _startDemo,
                    icon: const Icon(Icons.replay_rounded,
                        color: Color(0xFF7C4DFF)),
                    tooltip: 'Replay demo',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplash() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 52, color: Color(0xFF7C4DFF)),
          SizedBox(height: 16),
          Text(
            'AI Shopping Assistant',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Starting demo…',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Activity bar ──────────────────────────────────────────────────────────────

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({required this.activity});
  final AgUiActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3D3D7A)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: activity.progress,
              color: const Color(0xFF7C4DFF),
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            activity.label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (activity.progress != null) ...[
            const Spacer(),
            Text(
              '${(activity.progress! * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  color: Color(0xFF7C4DFF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pick prompt banner ────────────────────────────────────────────────────────

class _PickPromptBanner extends StatelessWidget {
  const _PickPromptBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.touch_app_outlined,
                color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tap to choose your product',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Product picker bottom sheet ───────────────────────────────────────────────

class _ProductPickerSheet extends StatelessWidget {
  const _ProductPickerSheet({
    required this.products,
    this.preSelected,
  });

  final List<ShoppingProduct> products;
  final ShoppingProduct? preSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Add to cart',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a product to add to your order',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Product tiles
          ...products.map((p) => _ProductTile(
                product: p,
                onTap: () => Navigator.of(context).pop(p),
              )),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});
  final ShoppingProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              product.gradient.first.withValues(alpha: 0.8),
              product.gradient.last.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: product.gradient.first.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(product.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text(product.tagline,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(product.price,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const Icon(Icons.add_circle_outline,
                    color: Colors.white70, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
