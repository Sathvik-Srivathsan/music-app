import 'package:flutter/material.dart';

/// A generic collapsible container that fully un-renders its [child] when
/// collapsed (the child is dropped from the tree, freeing its memory/GPU
/// work). Used at both the subsection level (via [StatSectionCard]) and the
/// individual chart level (via [ChartCard]).
class StatCollapsible extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final Widget header;
  final Widget? child;
  final EdgeInsets padding;

  /// Extra vertical space between the [header] and the [child] content.
  final double contentTopGap;

  const StatCollapsible({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.header,
    this.child,
    this.padding = EdgeInsets.zero,
    this.contentTopGap = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (expanded)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: contentTopGap),
                Padding(padding: padding, child: child ?? const SizedBox.shrink()),
              ],
            ),
          ),
      ],
    );
  }
}
