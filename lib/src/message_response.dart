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

  FileInfo _parseFileInfo(Map<dynamic, dynamic> fileJson) {
    return FileInfo(
      url: fileJson['url'],
      size: fileJson['size'],
      fileName: fileJson['fileName'] ?? '',
      contentType: fileJson['contentType'],
      imageInfo: null,
    );
  }

  Message transform() {
    Attachment? attachment;
    if (json['attachment'] != null && json['attachment'] is Map) {
      final attachmentJson = json['attachment'] as Map<dynamic, dynamic>;

      List<FileInfo> files = [];
      if (attachmentJson['filesList'] != null &&
          attachmentJson['filesList'] is List) {
        for (var fileJson in attachmentJson['filesList']) {
          files.add(_parseFileInfo(fileJson));
        }
      } else if (attachmentJson['filesInfo'] != null &&
          attachmentJson['filesInfo'] is Map) {
        files.add(_parseFileInfo(attachmentJson['filesInfo']));
      }

      AttachmentState state = AttachmentState.ERROR;
      if (attachmentJson['state'] != null) {
        switch (attachmentJson['state']) {
          case 'READY':
            state = AttachmentState.READY;
            break;
          case 'UPLOAD':
            state = AttachmentState.UPLOAD;
            break;
          case 'EXTERNAL_CHECKS':
            state = AttachmentState.EXTERNAL_CHECKS;
            break;
          default:
            state = AttachmentState.ERROR;
        }
      }

      attachment = Attachment(
        fileInfo: files.isNotEmpty ? files[0] : null,
        listFileInfo: files,
        state: state,
        errorType: attachmentJson['errorType'],
        errorMessage: attachmentJson['errorMessage'],
        visitorErrorMessage: attachmentJson['visitorErrorMessage'],
        downloadProgress: attachmentJson['downloadProgress'],
        extraText: attachmentJson['extraText'],
      );
    }

    // Parse quote
    Quote? quote;
    if (json['quote'] != null && json['quote'] is Map) {
      final quoteJson = json['quote'] as Map<dynamic, dynamic>;

      // Parse quote state
      QuoteState quoteState = QuoteState.NOT_FOUND;
      if (quoteJson['state'] != null) {
        switch (quoteJson['state']) {
          case 'PENDING':
            quoteState = QuoteState.PENDING;
            break;
          case 'FILLED':
            quoteState = QuoteState.FILLED;
            break;
          default:
            quoteState = QuoteState.NOT_FOUND;
        }
      }

      // Parse quoted message attachment
      FileInfo? messageAttachment;
      if (quoteJson['messageAttachment'] != null &&
          quoteJson['messageAttachment'] is Map) {
        final attachmentJson =
            quoteJson['messageAttachment'] as Map<dynamic, dynamic>;

        // Parse image info for quoted message attachment
        ImageInfo? imageInfo;
        if (attachmentJson['imageInfo'] != null &&
            attachmentJson['imageInfo'] is Map) {
          final imageInfoJson =
              attachmentJson['imageInfo'] as Map<dynamic, dynamic>;
          imageInfo = ImageInfo(
            thumbUrl: imageInfoJson['thumbUrl'] ?? '',
            width: imageInfoJson['width'],
            height: imageInfoJson['height'],
          );
        }

        messageAttachment = FileInfo(
          url: attachmentJson['url'],
          size: attachmentJson['size'],
          fileName: attachmentJson['fileName'] ?? '',
          contentType: attachmentJson['contentType'],
          imageInfo: imageInfo,
        );
      }

      // Parse quoted message type
      MessageType? messageType;
      if (quoteJson['messageType'] != null) {
        messageType = _MessageTypeResponse.fromString(
          quoteJson['messageType'],
        ).transform;
      }

      quote = Quote(
        state: quoteState,
        messageAttachment: messageAttachment,
        messageId: quoteJson['messageId'],
        messageType: messageType,
        senderName: quoteJson['senderName'],
        messageText: quoteJson['messageText'],
        messageTimestamp: quoteJson['messageTimestamp'],
        quotedMessageId: quoteJson['quotedMessageId'],
      );
    }

    Keyboard? keyboard;
    if (json['keyboard'] != null && json['keyboard'] is Map) {
      final keyboardJson = json['keyboard'] as Map<dynamic, dynamic>;

      KeyboardState keyboardState = KeyboardState.PENDING;
      if (keyboardJson['state'] != null) {
        switch (keyboardJson['state']) {
          case 'CANCELLED':
            keyboardState = KeyboardState.CANCELLED;
            break;
          case 'COMPLETED':
            keyboardState = KeyboardState.COMPLETED;
            break;
          default:
            keyboardState = KeyboardState.PENDING;
        }
      }

      List<List<KeyboardButton>> buttons = [];
      if (keyboardJson['buttons'] != null && keyboardJson['buttons'] is List) {
        for (var row in keyboardJson['buttons']) {
          if (row is List) {
            List<KeyboardButton> buttonRow = [];
            for (var buttonJson in row) {
              if (buttonJson is Map) {
                KeyboardButtonConfiguration? configuration;
                if (buttonJson['configuration'] != null &&
                    buttonJson['configuration'] is Map) {
                  final configJson =
                      buttonJson['configuration'] as Map<dynamic, dynamic>;

                  KeyboardButtonType buttonType = KeyboardButtonType.URL_BUTTON;
                  if (configJson['buttonType'] != null) {
                    switch (configJson['buttonType']) {
                      case 'INSERT_BUTTON':
                        buttonType = KeyboardButtonType.INSERT_BUTTON;
                        break;
                      default:
                        buttonType = KeyboardButtonType.URL_BUTTON;
                    }
                  }

                  KeyboardButtonState buttonState = KeyboardButtonState.SHOWING;
                  if (configJson['state'] != null) {
                    switch (configJson['state']) {
                      case 'SHOWING_SELECTED':
                        buttonState = KeyboardButtonState.SHOWING_SELECTED;
                        break;
                      case 'HIDDEN':
                        buttonState = KeyboardButtonState.HIDDEN;
                        break;
                      default:
                        buttonState = KeyboardButtonState.SHOWING;
                    }
                  }

                  configuration = KeyboardButtonConfiguration(
                    buttonType: buttonType,
                    data: configJson['data'] ?? '',
                    state: buttonState,
                  );
                }

                KeyboardButtonParams? params;
                if (buttonJson['params'] != null &&
                    buttonJson['params'] is Map) {
                  final paramsJson =
                      buttonJson['params'] as Map<dynamic, dynamic>;

                  KeyboardButtonParamsType paramsType =
                      KeyboardButtonParamsType.URL;
                  if (paramsJson['type'] != null) {
                    switch (paramsJson['type']) {
                      case 'ACTION':
                        paramsType = KeyboardButtonParamsType.ACTION;
                        break;
                      default:
                        paramsType = KeyboardButtonParamsType.URL;
                    }
                  }

                  params = KeyboardButtonParams(
                    type: paramsType,
                    action: paramsJson['action'],
                    color: paramsJson['color'],
                  );
                }

                buttonRow.add(
                  KeyboardButton(
                    id: buttonJson['id'] ?? '',
                    text: buttonJson['text'] ?? '',
                    configuration: configuration,
                    params: params,
                  ),
                );
              }
            }
            buttons.add(buttonRow);
          }
        }
      }

      KeyboardResponse? keyboardResponse;
      if (keyboardJson['keyboardResponse'] != null &&
          keyboardJson['keyboardResponse'] is Map) {
        final responseJson =
            keyboardJson['keyboardResponse'] as Map<dynamic, dynamic>;
        keyboardResponse = KeyboardResponse(
          buttonId: responseJson['buttonId'] ?? '',
          messageId: responseJson['messageId'] ?? '',
        );
      }

      keyboard = Keyboard(
        buttons: buttons,
        state: keyboardState,
        keyboardResponse: keyboardResponse,
      );
    }

    KeyboardRequest? keyboardRequest;
    if (json['keyboardRequest'] != null && json['keyboardRequest'] is Map) {
      final requestJson = json['keyboardRequest'] as Map<dynamic, dynamic>;

      KeyboardButton? button;
      if (requestJson['buttons'] != null && requestJson['buttons'] is Map) {
        final buttonJson = requestJson['buttons'] as Map<dynamic, dynamic>;

        KeyboardButtonConfiguration? configuration;
        if (buttonJson['configuration'] != null &&
            buttonJson['configuration'] is Map) {
          final configJson =
              buttonJson['configuration'] as Map<dynamic, dynamic>;

          KeyboardButtonType buttonType = KeyboardButtonType.URL_BUTTON;
          if (configJson['buttonType'] != null) {
            switch (configJson['buttonType']) {
              case 'INSERT_BUTTON':
                buttonType = KeyboardButtonType.INSERT_BUTTON;
                break;
              default:
                buttonType = KeyboardButtonType.URL_BUTTON;
            }
          }

          KeyboardButtonState buttonState = KeyboardButtonState.SHOWING;
          if (configJson['state'] != null) {
            switch (configJson['state']) {
              case 'SHOWING_SELECTED':
                buttonState = KeyboardButtonState.SHOWING_SELECTED;
                break;
              case 'HIDDEN':
                buttonState = KeyboardButtonState.HIDDEN;
                break;
              default:
                buttonState = KeyboardButtonState.SHOWING;
            }
          }

          configuration = KeyboardButtonConfiguration(
            buttonType: buttonType,
            data: configJson['data'] ?? '',
            state: buttonState,
          );
        }

        KeyboardButtonParams? params;
        if (buttonJson['params'] != null && buttonJson['params'] is Map) {
          final paramsJson = buttonJson['params'] as Map<dynamic, dynamic>;

          // Parse params type
          KeyboardButtonParamsType paramsType = KeyboardButtonParamsType.URL;
          if (paramsJson['type'] != null) {
            switch (paramsJson['type']) {
              case 'ACTION':
                paramsType = KeyboardButtonParamsType.ACTION;
                break;
              default:
                paramsType = KeyboardButtonParamsType.URL;
            }
          }

          params = KeyboardButtonParams(
            type: paramsType,
            action: paramsJson['action'],
            color: paramsJson['color'],
          );
        }

        button = KeyboardButton(
          id: buttonJson['id'] ?? '',
          text: buttonJson['text'] ?? '',
          configuration: configuration,
          params: params,
        );
      }

      keyboardRequest = KeyboardRequest(
        buttons: button,
        messageId: requestJson['messageId'] ?? '',
      );
    }

    Sticker? sticker;
    if (json['sticker'] != null && json['sticker'] is Map) {
      final stickerJson = json['sticker'] as Map<dynamic, dynamic>;
      sticker = Sticker(stickerId: stickerJson['stickerId'] ?? 0);
    }

    GroupData? groupData;
    if (json['groupData'] != null && json['groupData'] is Map) {
      final groupDataJson = json['groupData'] as Map<dynamic, dynamic>;
      groupData = GroupData(groupId: groupDataJson['groupId'] ?? '');
    }

    return Message(
      clientSideId: json['clientSideId'] != null && json['clientSideId'] is Map
          ? (json['clientSideId']['id'] ?? '')
          : '',
      sessionId: json['sessionId'],
      serverSideId: json['serverSideId'],
      operatorId: json['operatorId'],
      senderAvatarUrl: json['senderAvatarUrl'],
      senderName: json['senderName'] ?? '',
      type: json['type'] != null
          ? _MessageTypeResponse.fromString(json['type']).transform
          : MessageType.INFO,
      time: DateTime.fromMicrosecondsSinceEpoch((json['time'] * 1000).toInt()),
      text: json['text'] ?? '',
      sendStatus: json['sendStatus'] == 'SENT'
          ? SendStatus.SENT
          : (json['sendStatus'] == 'FAILED'
                ? SendStatus.FAILED
                : SendStatus.SENDING),
      data: json['data'],
      isSavedInHistory: json['savedInHistory'] ?? false,
      isReadByOperator: json['readByOperator'] ?? false,
      canBeEdited: json['canBeEdited'] ?? false,
      canBeReplied: json['canBeReplied'] ?? false,
      isEdited: json['edited'] ?? false,
      quote: quote,
      reaction: MessageReaction.fromString(json['reaction'] ?? ''),
      canVisitorReact: json['canVisitorReact'] ?? false,
      canVisitorChangeReaction: json['canVisitorChangeReaction'] ?? false,
      groupData: groupData,
      keyboard: keyboard,
      keyboardRequest: keyboardRequest,
      sticker: sticker,
      attachment: attachment,
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
        type = MessageType.OPERATOR;
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
        throw Exception('Unknown message type: $row');
    }
    return _MessageTypeResponse._(type);
  }

  MessageType get transform => _type;
}
