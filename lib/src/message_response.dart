import 'dart:convert';

import 'package:webim/src/message.dart';

/// [Message] response parser

class MessageResponse {
  final Map<dynamic, dynamic> json;

  MessageResponse._(this.json);

  factory MessageResponse.fromJson(dynamic row) {
    final json = (row is String) ? jsonDecode(row) : row;
    return MessageResponse._(json);
  }

  Message transform() {
    return Message(
      canBeEdited: json['canBeEdited'],
      canBeReplied: json['canBeReplied'],
      clientSideId: json['clientSideId']['id'],
      isEdited: json['edited'],
      isReadByOperator: json['readByOperator'],
      isSavedInHistory: json['savedInHistory'],
      sendStatus: json['sendStatus'] == 'SENT'
          ? SendStatus.SENT
          : SendStatus.SENDING,
      senderName: json['senderName'],
      serverSideId: json['serverSideId'],
      text: json['text'],
      time: DateTime.fromMicrosecondsSinceEpoch(json['timeMicros']),
      type: json['type'] != null
          ? _MessageTypeResponse.fromString(json['type']).transform
          : MessageType.INFO,
    );
  }
}

/// List<[Message]> response parser

class ListMessageResponse {
  final List<dynamic> json;

  ListMessageResponse._(this.json);

  factory ListMessageResponse.fromJson(dynamic row) {
    final json = (row is String) ? jsonDecode(row) : row;
    return ListMessageResponse._(json);
  }

  List<Message> transform() {
    return json.map((e) => MessageResponse.fromJson(e).transform()).toList();
  }
}

/// [MessageType] response parser
class _MessageTypeResponse {
  final MessageType _type;

  _MessageTypeResponse._(this._type);

  factory _MessageTypeResponse.fromString(String row) {
    MessageType type;
    switch (row) {
      case 'ACTION_REQUEST':
        type = MessageType.ACTION_REQUEST;
        break;
      case 'CONTACT_REQUEST':
        type = MessageType.CONTACT_REQUEST;
        break;
      case 'FILE_FROM_OPERATOR':
        type = MessageType.FILE_FROM_OPERATOR;
        break;
      case 'FILE_FROM_VISITOR':
        type = MessageType.FILE_FROM_VISITOR;
        break;
      case 'INFO':
        type = MessageType.INFO;
        break;
      case 'KEYBOARD':
        type = MessageType.KEYBOARD;
        break;
      case 'KEYBOARD_RESPONSE':
        type = MessageType.KEYBOARD_RESPONSE;
        break;
      case 'OPERATOR':
        type = MessageType.ACTION_REQUEST;
        break;
      case 'OPERATOR_BUSY':
        type = MessageType.OPERATOR_BUSY;
        break;
      case 'STICKER_VISITOR':
        type = MessageType.STICKER_VISITOR;
        break;
      case 'VISITOR':
        type = MessageType.VISITOR;
        break;
      default:
        throw Exception('Unknown message type');
    }
    return _MessageTypeResponse._(type);
  }

  MessageType get transform => _type;
}
