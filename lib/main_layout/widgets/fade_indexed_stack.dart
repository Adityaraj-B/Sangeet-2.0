import 'package:flutter/material.dart';

/// A state-preserving crossfade navigator.
///
/// Replaces [IndexedStack] and animates between children with a smooth fade
/// whenever [index] changes.
///
/// All children that have been visited remain mounted (but invisible) so that
/// scroll positions, form state, and BLoC state survive tab switches.
/// Children that have never been visited are never built at all (lazy).
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 280),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  /// Which index is being shown right now (the "incoming" tab).
  late int _activeIndex;

  /// Which index was previously visible (the "outgoing" tab), or -1 if none.
  int _prevIndex = -1;

  /// Whether a crossfade animation is in progress.
  bool _transitioning = false;

  /// Which indices have ever been mounted (lazy activation).
  final Set<int> _visited = {};

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.index;
    _visited.add(_activeIndex);

    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0, // Start fully opaque — no animation on first frame.
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && _transitioning) {
        setState(() {
          _prevIndex = -1;
          _transitioning = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (widget.index != _activeIndex) {
      // setState here so Offstage rebuilds immediately to show both tabs.
      setState(() {
        _prevIndex = _activeIndex;
        _activeIndex = widget.index;
        _visited.add(_activeIndex);
        _transitioning = true;
      });
      // Start animating AFTER setState has been scheduled.
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Background: all previously-visited tabs kept alive offstage ────
        for (int i = 0; i < widget.children.length; i++)
          if (_visited.contains(i) && i != _activeIndex && i != _prevIndex)
            Offstage(
              // offstage = true means hidden but still in the element tree.
              child: TickerMode(
                enabled: false,
                child: widget.children[i],
              ),
            ),

        // ── 2. Outgoing tab: fades from 1 → 0, non-interactive ───────────────
        if (_transitioning && _prevIndex >= 0)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Opacity(
              opacity: (1.0 - _ctrl.value).clamp(0.0, 1.0),
              child: child,
            ),
            child: IgnorePointer(
              child: widget.children[_prevIndex],
            ),
          ),

        // ── 3. Incoming / active tab: fades from 0 → 1 ───────────────────────
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Opacity(
            opacity: _transitioning
                ? _ctrl.value.clamp(0.0, 1.0)
                : 1.0, // No animation needed when idle.
            child: child,
          ),
          child: widget.children[_activeIndex],
        ),
      ],
    );
  }
}
