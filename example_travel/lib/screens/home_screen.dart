/// AI Trip Planner home screen.
///
/// Demonstrates the full AG-UI feature set in a polished dark-themed travel UI:
///   • Broadcast stream → 4 controllers in parallel
///   • Reasoning block, step-tracked tool call cards, streaming text
///   • FlightCard + HotelCard rendered via AgUiWidgetRegistry
///   • Activity indicator with progress + description
///   • State-synced itinerary bar at the bottom
///   • Human-in-the-loop booking confirmation bottom sheet
library;

import 'dart:async';

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter/material.dart';

import '../data/demo_stream.dart';
import '../data/travel_models.dart';
import '../widgets/flight_card.dart';
import '../widgets/hotel_card.dart';
import '../widgets/itinerary_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Controllers ──────────────────────────────────────────────────────────────
  AgUiRunLifecycleController? _lifecycle;
  AgUiActivityController? _activity;
  AgUiStateController? _stateCtrl;
  AgUiGenerativeController? _genCtrl;

  // ── UI state ─────────────────────────────────────────────────────────────────
  bool _running = false;
  bool _waitingForBooking = false;
  bool _done = false;
  Map<String, dynamic> _itinerary = const {};

  // ── Widget registry ──────────────────────────────────────────────────────────
  late final AgUiWidgetRegistry _registry = AgUiWidgetRegistry({
    'FlightCard': (_, props) {
      final id = jsonStr(props, 'id');
      final flight = flightById(id);
      if (flight == null) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Unknown flight: $id',
              style: const TextStyle(color: Colors.red)),
        );
      }
      return TravelFlightCard(flight: flight);
    },
    'HotelCard': (_, props) {
      final id = jsonStr(props, 'id');
      final hotel = hotelById(id);
      if (hotel == null) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Unknown hotel: $id',
              style: const TextStyle(color: Colors.red)),
        );
      }
      return TravelHotelCard(hotel: hotel);
    },
  });

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 700), _startDemo);
  }

  // ── Demo lifecycle ────────────────────────────────────────────────────────────

  void _startDemo() {
    _disposeAll();
    final broadcast = buildDemoStream().asBroadcastStream();

    final lifecycle = AgUiRunLifecycleController(events: broadcast);
    final activity = AgUiActivityController(events: broadcast);
    final stateCtrl = AgUiStateController(events: broadcast);
    final genCtrl =
        AgUiGenerativeController(events: broadcast, widgetRegistry: _registry);

    lifecycle.addListener(() => _onLifecycle(lifecycle));
    activity.addListener(() {
      if (mounted) setState(() {});
    });
    stateCtrl.addListener(() {
      if (!mounted) return;
      setState(() => _itinerary = stateCtrl.state);
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
      _waitingForBooking = false;
      _done = false;
      _itinerary = const {};
    });
  }

  void _onLifecycle(AgUiRunLifecycleController lc) {
    if (!mounted) return;
    if (lc.isInterrupted) {
      setState(() {
        _running = false;
        _waitingForBooking = true;
      });
      Future.delayed(
          const Duration(milliseconds: 700), () => _showBookingSheet());
    } else if (lc.isFinished) {
      setState(() {
        _running = false;
        _done = true;
      });
    } else {
      setState(() {});
    }
  }

  void _showBookingSheet() {
    if (!mounted || !_waitingForBooking) return;
    showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _BookingSheet(
        onConfirm: () => Navigator.of(ctx).pop(true),
        onDecline: () => Navigator.of(ctx).pop(false),
      ),
    ).then((confirmed) {
      if (confirmed == true) _resumeWithBooking();
    });
  }

  void _resumeWithBooking() {
    _disposeAll();
    setState(() {
      _waitingForBooking = false;
      _running = true;
      _done = false;
    });

    final resumeBroadcast = buildResumeStream().asBroadcastStream();

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
      setState(() => _itinerary = stateCtrl.state);
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
    final currentActivity = _activity?.current;
    final genCtrl = _genCtrl;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Search pill ────────────────────────────────────────────────────
          _SearchPill(running: _running),

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
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    emptyBuilder: (_) => _buildSplash(),
                  ),
          ),

          // ── Booking prompt ─────────────────────────────────────────────────
          if (_waitingForBooking)
            _BookingPromptBanner(onTap: _showBookingSheet),

          // ── Itinerary bar ──────────────────────────────────────────────────
          ItineraryBar(state: _itinerary),
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
            colors: [Color(0xFF122236), Color(0xFF0A1628)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            bottom: BorderSide(color: Color(0xFF1E3850), width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flight_takeoff_rounded,
                      color: Color(0xFF00B4D8), size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('AI Trip Planner',
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
                                : _waitingForBooking
                                    ? Colors.orange
                                    : _done
                                        ? const Color(0xFF00B4D8)
                                        : Colors.white30,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _running
                              ? 'Searching…'
                              : _waitingForBooking
                                  ? 'Waiting for confirmation'
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
                if (_done || (!_running && _genCtrl != null))
                  IconButton(
                    onPressed: _startDemo,
                    icon: const Icon(Icons.replay_rounded,
                        color: Color(0xFF00B4D8)),
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
          Icon(Icons.flight_takeoff_rounded,
              size: 56, color: Color(0xFF00B4D8)),
          SizedBox(height: 16),
          Text(
            'AI Trip Planner',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Starting demo…',
            style: TextStyle(color: Colors.white30, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Search pill ───────────────────────────────────────────────────────────────

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.running});
  final bool running;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF122236),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3850)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '3 days in Barcelona — mid June',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          if (running)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00B4D8),
              ),
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
    final progress = activity.progress;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF122A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E4060)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress,
              color: const Color(0xFF00B4D8),
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activity.label,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (activity.description != null)
                  Text(
                    activity.description!,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10),
                  ),
              ],
            ),
          ),
          if (progress != null)
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  color: Color(0xFF00B4D8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

// ── Booking prompt banner ─────────────────────────────────────────────────────

class _BookingPromptBanner extends StatelessWidget {
  const _BookingPromptBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B4D8).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tap to confirm your booking',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Booking confirmation bottom sheet ─────────────────────────────────────────

class _BookingSheet extends StatelessWidget {
  const _BookingSheet({required this.onConfirm, required this.onDecline});

  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF122236),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
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
          const SizedBox(height: 24),

          // Title
          const Row(
            children: [
              Text('✈️', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm Booking',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Review your trip before confirming',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Flight summary
          const _SummaryTile(
            icon: Icons.flight_rounded,
            iconColor: Color(0xFF00B4D8),
            title: 'Vueling VY 1234',
            subtitle: 'CDG → BCN  |  08:30 – 10:45  |  Economy Plus',
            price: '€189',
          ),
          const SizedBox(height: 10),

          // Hotel summary
          const _SummaryTile(
            icon: Icons.hotel_rounded,
            iconColor: Color(0xFF48CAE4),
            title: 'Hotel Arts Barcelona',
            subtitle: 'Barceloneta  |  3 nights  |  Pool & sea view',
            price: '€960',
          ),

          const SizedBox(height: 20),

          // Total
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C3248),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                Spacer(),
                Text(
                  '€1,149',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Color(0xFF2A4A6A)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Maybe later'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B4D8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Confirm Booking ✈️',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.price,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C3248),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A4A6A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Text(price,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
