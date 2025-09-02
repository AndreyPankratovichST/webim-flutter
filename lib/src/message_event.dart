
import 'package:flutter/foundation.dart';

import 'package:webim/webim.dart';

sealed class MessageEvent {
  factory MessageEvent.removedAll() => MessageEventRemovedAll();
  factory MessageEvent.removed(Message message) => MessageEventRemoved(message);
  factory MessageEvent.added(Message message) => MessageEventAdded(message);
  factory MessageEvent.changed({
    required Message from,
    required Message to,
  }) =>
      MessageEventChanged(from, to);
}

@immutable
class MessageEventAdded implements MessageEvent {
  const MessageEventAdded(this.message);
  final Message message;

  @override
  String toString() {
    return 'MessageEventAdded(message: $message)';
  }
}

@immutable
class MessageEventChanged implements MessageEvent {
  const MessageEventChanged(this.from, this.to);
  final Message from;
  final Message to;

  @override
  String toString() {
    return 'MessageEventChanged(from: $from, to: $to)';
  }
}

@immutable
class MessageEventRemoved implements MessageEvent {
  const MessageEventRemoved(this.message);
  final Message message;

  @override
  String toString() {
    return 'MessageEventRemoved(message: $message)';
  }
}

@immutable
class MessageEventRemovedAll implements MessageEvent {}