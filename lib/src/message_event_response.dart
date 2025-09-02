import 'dart:convert';

import 'package:webim/src/message_response.dart';
import 'package:webim/webim.dart';

/// [MessageEvent] response parser

class MessageEventResponse {
  MessageEventResponse(this.row);

  dynamic row;

  MessageEvent? transform() {
    final json = (row is Map ? row : jsonDecode(row)) as Map<dynamic, dynamic>;

    if (json.keys.contains('added')) {
      return MessageEvent.added(MessageResponse.fromJson(json['added']).transform());
    }

    if (json.keys.contains('removed')) {
      return MessageEvent.removed(MessageResponse.fromJson(json['removed']).transform());
    }

    if (json.keys.contains('from') && json.keys.contains('to')) {
      return MessageEvent.changed(
        from: MessageResponse.fromJson(json['from']).transform(),
        to: MessageResponse.fromJson(json['to']).transform(),
      );
    }

    if (json.keys.contains('removedAll')) {
      return MessageEvent.removedAll();
    }

    return null;
  }
}
