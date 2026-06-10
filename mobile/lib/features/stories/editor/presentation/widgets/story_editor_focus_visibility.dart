import 'package:flutter/widgets.dart';

class StoryEditorRevealOnFocus extends StatelessWidget {
  const StoryEditorRevealOnFocus({
    super.key,
    required this.child,
    this.onFocus,
  });

  final Widget child;
  final ValueChanged<BuildContext>? onFocus;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onFocus?.call(context),
      child: Focus(
        skipTraversal: true,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            onFocus?.call(context);
          }
        },
        child: child,
      ),
    );
  }
}
