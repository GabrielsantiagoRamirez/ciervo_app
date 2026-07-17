import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Reconocedores de gestos para que un `GoogleMap` dentro de una vista
/// scrolleable capture el zoom (pellizco) y el desplazamiento con los dedos,
/// en lugar de cederlos al scroll padre.
final Set<Factory<OneSequenceGestureRecognizer>> mapEagerGestureRecognizers = {
  Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
};
