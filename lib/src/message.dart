/// Abstracts a single message in the message history.
class Message implements Comparable<Message> {
  /// unique client id of the message
  final String clientSideId;

  /// session id for current message
  final String? sessionId;

  /// unique server id of the message
  final String? serverSideId;

  /// id of a sender, if the sender is an operator
  final String? operatorId;

  /// URL of a sender's avatar
  final String? senderAvatarUrl;

  /// name of a message sender
  final String senderName;

  /// type of a message
  final MessageType type;

  /// time the message was processed by the server
  final DateTime time;

  /// text of the message
  final String text;

  /// send status of the message
  final SendStatus sendStatus;

  /// custom data for ACTION_REQUEST messages
  final String? data;

  /// whether this message is saved in history
  final bool isSavedInHistory;

  /// whether this visitor message is read by operator
  final bool isReadByOperator;

  /// whether this message can be edited
  final bool canBeEdited;

  /// whether this message can be replied
  final bool canBeReplied;

  /// whether this message was edited
  final bool isEdited;

  /// information about quoted message
  final Quote? quote;

  /// reaction to the message
  final MessageReaction? reaction;

  /// whether visitor can react to this message
  final bool canVisitorReact;

  /// whether visitor can change reaction to this message
  final bool canVisitorChangeReaction;

  /// group data of the message
  final GroupData? groupData;

  /// keyboard attached to the message
  final Keyboard? keyboard;

  /// keyboard request information
  final KeyboardRequest? keyboardRequest;

  /// sticker attached to the message
  final Sticker? sticker;

  /// attachment attached to the message
  final Attachment? attachment;

  Message({
    required this.clientSideId,
    this.sessionId,
    this.serverSideId,
    this.operatorId,
    this.senderAvatarUrl,
    required this.senderName,
    required this.type,
    required this.time,
    required this.text,
    required this.sendStatus,
    this.data,
    required this.isSavedInHistory,
    required this.isReadByOperator,
    required this.canBeEdited,
    required this.canBeReplied,
    required this.isEdited,
    this.quote,
    this.reaction,
    required this.canVisitorReact,
    required this.canVisitorChangeReaction,
    this.groupData,
    this.keyboard,
    this.keyboardRequest,
    this.sticker,
    this.attachment,
  });

  @override
  bool operator ==(Object other) {
    if (other is Message) {
      return other.clientSideId == clientSideId;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => clientSideId.hashCode;

  @override
  int compareTo(Message other) => time.compareTo(other.time);

  @override
  String toString() {
    return 'Message('
        'clientSideId: $clientSideId, '
        'sessionId: $sessionId, '
        'serverSideId: $serverSideId, '
        'operatorId: $operatorId, '
        'senderAvatarUrl: $senderAvatarUrl, '
        'senderName: $senderName, '
        'type: $type, '
        'time: $time, '
        'text: $text, '
        'sendStatus: $sendStatus, '
        'data: $data, '
        'isSavedInHistory: $isSavedInHistory, '
        'isReadByOperator: $isReadByOperator, '
        'canBeEdited: $canBeEdited, '
        'canBeReplied: $canBeReplied, '
        'isEdited: $isEdited, '
        'quote: $quote, '
        'reaction: $reaction, '
        'canVisitorReact: $canVisitorReact, '
        'canVisitorChangeReaction: $canVisitorChangeReaction, '
        'groupData: $groupData, '
        'keyboard: $keyboard, '
        'keyboardRequest: $keyboardRequest, '
        'sticker: $sticker, '
        'attachment: $attachment)';
  }
}

/// Type of [Message]
enum MessageType {
  ACTION_REQUEST,
  CONTACT_REQUEST,
  FILE_FROM_OPERATOR,
  FILE_FROM_VISITOR,
  INFO,
  KEYBOARD,
  KEYBOARD_RESPONSE,
  OPERATOR,
  OPERATOR_BUSY,
  STICKER_VISITOR,
  VISITOR,
}

enum SendStatus {
  SENDING,
  SENT,
  FAILED,
}

/// Contains a file attached to the message.
class Attachment {
  final FileInfo? fileInfo;
  final List<FileInfo> listFileInfo;
  final AttachmentState state;
  final String? errorType;
  final String? errorMessage;
  final String? visitorErrorMessage;
  final int? downloadProgress;
  final String? extraText;

  Attachment({
    this.fileInfo,
    required this.listFileInfo,
    required this.state,
    this.errorType,
    this.errorMessage,
    this.visitorErrorMessage,
    this.downloadProgress,
    this.extraText,
  });

  @override
  String toString() {
    return 'Attachment('
        'fileInfo: $fileInfo, '
        'listFileInfo: $listFileInfo, '
        'state: $state, '
        'errorType: $errorType, '
        'errorMessage: $errorMessage, '
        'visitorErrorMessage: $visitorErrorMessage, '
        'downloadProgress: $downloadProgress, '
        'extraText: $extraText)';
  }
}

/// Shows the state of the attachment.
enum AttachmentState {
  ERROR,
  READY,
  UPLOAD,
  EXTERNAL_CHECKS,
}

/// Contains information about attachment properties.
class FileInfo {
  final String? url;
  final int? size;
  final String fileName;
  final String? contentType;
  final ImageInfo? imageInfo;
  FileInfo({
    this.url,
    this.size,
    required this.fileName,
    this.contentType,
    this.imageInfo,
  });

  @override
  String toString() {
    return 'FileInfo('
        'url: $url, '
        'size: $size, '
        'fileName: $fileName, '
        'contentType: $contentType, '
        'imageInfo: $imageInfo)';
  }
}

/// Contains information about an image.
class ImageInfo {
  final String thumbUrl;
  final int? width;
  final int? height;

  ImageInfo({
    required this.thumbUrl,
    this.width,
    this.height,
  });

  @override
  String toString() {
    return 'ImageInfo('
        'thumbUrl: $thumbUrl, '
        'width: $width, '
        'height: $height)';
  }
}

/// Contains information about quoted message.
class Quote {
  final QuoteState state;
  final FileInfo? messageAttachment;
  final String? messageId;
  final MessageType? messageType;
  final String? senderName;
  final String? messageText;
  final int? messageTimestamp;
  final String? quotedMessageId;

  Quote({
    required this.state,
    this.messageAttachment,
    this.messageId,
    this.messageType,
    this.senderName,
    this.messageText,
    this.messageTimestamp,
    this.quotedMessageId,
  });

  @override
  String toString() {
    return 'Quote('
        'state: $state, '
        'messageAttachment: $messageAttachment, '
        'messageId: $messageId, '
        'messageType: $messageType, '
        'senderName: $senderName, '
        'messageText: $messageText, '
        'messageTimestamp: $messageTimestamp, '
        'quotedMessageId: $quotedMessageId)';
  }
}

/// Shows the state of the quoted message.
enum QuoteState {
  PENDING,
  FILLED,
  NOT_FOUND,
}

/// Contains information about reaction to a message.
enum MessageReaction {
  DISLIKE,
  LIKE;

  static MessageReaction? fromString(String value) {
    switch (value) {
      case 'dislike':
        return DISLIKE;
      case 'like':
        return LIKE;
      default:
        return null;
    }
  }
}

/// Contains information about message group.
class GroupData {
  final String groupId;

  GroupData({
    required this.groupId,
  });

  @override
  String toString() {
    return 'GroupData('
        'groupId: $groupId)';
  }
}

/// Contains information about keyboard item.
class Keyboard {
  final List<List<KeyboardButton>> buttons;
  final KeyboardState? state;
  final KeyboardResponse? keyboardResponse;

  Keyboard({
    required this.buttons,
    this.state,
    this.keyboardResponse,
  });

  @override
  String toString() {
    return 'Keyboard('
        'buttons: $buttons, '
        'state: $state, '
        'keyboardResponse: $keyboardResponse)';
  }
}

/// Shows the state of the keyboard.
enum KeyboardState {
  PENDING,
  CANCELLED,
  COMPLETED,
}

/// Contains information about buttons in keyboard item.
class KeyboardButton {
  final String id;
  final String text;
  final KeyboardButtonConfiguration? configuration;
  final KeyboardButtonParams? params;

  KeyboardButton({
    required this.id,
    required this.text,
    this.configuration,
    this.params,
  });

  @override
  String toString() {
    return 'KeyboardButton('
        'id: $id, '
        'text: $text, '
        'configuration: $configuration, '
        'params: $params)';
  }
}

/// Contains configuration of keyboard button.
class KeyboardButtonConfiguration {
  final KeyboardButtonType buttonType;
  final String data;
  final KeyboardButtonState state;

  KeyboardButtonConfiguration({
    required this.buttonType,
    required this.data,
    required this.state,
  });

  @override
  String toString() {
    return 'KeyboardButtonConfiguration('
        'buttonType: $buttonType, '
        'data: $data, '
        'state: $state)';
  }
}

/// Type of keyboard button.
enum KeyboardButtonType {
  URL_BUTTON,
  INSERT_BUTTON,
}

/// State of keyboard button.
enum KeyboardButtonState {
  SHOWING,
  SHOWING_SELECTED,
  HIDDEN,
}

/// Contains parameters of keyboard button.
class KeyboardButtonParams {
  final KeyboardButtonParamsType type;
  final String? action;
  final String? color;

  KeyboardButtonParams({
    required this.type,
    this.action,
    this.color,
  });

  @override
  String toString() {
    return 'KeyboardButtonParams('
        'type: $type, '
        'action: $action, '
        'color: $color)';
  }
}

/// Type of keyboard button parameters.
enum KeyboardButtonParamsType {
  URL,
  ACTION,
}

/// Contains information about the pressed button in keyboard item.
class KeyboardResponse {
  final String buttonId;
  final String messageId;

  KeyboardResponse({
    required this.buttonId,
    required this.messageId,
  });

  @override
  String toString() {
    return 'KeyboardResponse('
        'buttonId: $buttonId, '
        'messageId: $messageId)';
  }
}

/// Contains information about the pressed button in keyboard item.
class KeyboardRequest {
  final KeyboardButton? buttons;
  final String messageId;

  KeyboardRequest({
    this.buttons,
    required this.messageId,
  });

  @override
  String toString() {
    return 'KeyboardRequest('
        'buttons: $buttons, '
        'messageId: $messageId)';
  }
}

/// Contains information about sticker.
class Sticker {
  final int stickerId;

  Sticker({
    required this.stickerId,
  });

  @override
  String toString() {
    return 'Sticker('
        'stickerId: $stickerId)';
  }
}
