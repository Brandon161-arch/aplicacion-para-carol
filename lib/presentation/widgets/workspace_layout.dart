import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Distribuye el espacio de trabajo en 3 columnas (escritorio), 2 (tablet)
/// o una sola columna con scroll (móvil). La vista 3D queda fija en escritorio
/// y tablet; en móvil va primero y el resto se apila en un único scroll.
class WorkspaceLayout extends StatelessWidget {
  final Widget header;
  final Widget left;
  final Widget viewer;
  final Widget right;
  final bool freezeLeftScroll;

  const WorkspaceLayout({
    super.key,
    required this.header,
    required this.left,
    required this.viewer,
    required this.right,
    this.freezeLeftScroll = false,
  });

  static const double _desktopBreakpoint = 1280;
  static const double _tabletBreakpoint = 900;
  static const double _leftWidth = 340;
  static const double _rightWidth = 460;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= _desktopBreakpoint) {
          return _Frame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: _leftWidth,
                        child: _Pane(
                          physics: freezeLeftScroll
                              ? const NeverScrollableScrollPhysics()
                              : null,
                          child: left,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: viewer),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: _rightWidth,
                        child: _Pane(child: right),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (width >= _tabletBreakpoint) {
          final viewerHeight = (constraints.maxHeight * 0.5).clamp(
            320.0,
            560.0,
          );
          return _Frame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: _leftWidth,
                        child: _Pane(
                          physics: freezeLeftScroll
                              ? const NeverScrollableScrollPhysics()
                              : null,
                          child: left,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(height: viewerHeight, child: viewer),
                            const SizedBox(height: 12),
                            Expanded(child: _Pane(child: right)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return _Frame(
          child: _Pane(
            physics: freezeLeftScroll
                ? const NeverScrollableScrollPhysics()
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 12),
                SizedBox(
                  height: math.min(420, constraints.maxHeight * 0.55),
                  child: viewer,
                ),
                const SizedBox(height: 14),
                left,
                const SizedBox(height: 14),
                right,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  final Widget child;

  const _Frame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1900),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: child,
        ),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  final Widget child;
  final ScrollPhysics? physics;

  const _Pane({required this.child, this.physics});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: physics,
      padding: const EdgeInsets.only(right: 2, bottom: 16),
      child: child,
    );
  }
}
