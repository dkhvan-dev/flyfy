import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

Set<Factory<OneSequenceGestureRecognizer>> appMapGestureRecognizers() {
  return <Factory<OneSequenceGestureRecognizer>>{
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };
}
