import 'package:flutter/material.dart';

class AppKeyboardDismissOnScroll extends StatelessWidget {
  const AppKeyboardDismissOnScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis != Axis.vertical) {
          return false;
        }

        final isUserDrag = switch (notification) {
          ScrollStartNotification(:final dragDetails) => dragDetails != null,
          ScrollUpdateNotification(:final dragDetails) => dragDetails != null,
          OverscrollNotification(:final dragDetails) => dragDetails != null,
          _ => false,
        };

        if (isUserDrag) {
          FocusManager.instance.primaryFocus?.unfocus();
        }

        return false;
      },
      child: child,
    );
  }
}
