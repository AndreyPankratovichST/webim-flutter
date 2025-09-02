/// Abstracts a single message in the message history. A message is an immutable object. It means that for changing
/// some of the message fields there will be created a new object. That is why messages can be compared by using ({@code equals}) for searching messages
/// with the same set of fields or by id ({@code msg1.getId().equals(msg2.getId())}) for searching logically identical messages. Id is formed
/// on the client side when sending a message ({@link MessageStream#sendMessage} or {@link MessageStream#sendFile}).
class Message implements Comparable<Message> {
  /// return unique client id of the message. Notice that id does not change while changing the content of a message.
  final String clientSideId;

  /// return session id for current message.
  final String? sessionId;

  /// return unique server id of the message.
  final String? serverSideId;

  /// return id of a sender, if the sender is an operator
  final String? operatorId;

  /// return URL of a sender's avatar
  final String? senderAvatarUrl;

  /// return name of a message sender
  final String senderName;

  /// return type of a message
  final MessageType type;

  /// return time the message was processed by the server
  final DateTime time;

  /// return text of the message
  final String text;

  /// return [SendStatus.SENT] if a message had been sent to the server, was received by the server and was
  /// delivered to all the clients;
  /// [SendStatus.SENDING] if not
  final SendStatus sendStatus;

  /// Messages of the types {@link Type#FILE_FROM_OPERATOR} and [MessageType.FILE_FROM_VISITOR] can contain attachments.
  /// Notice that this method may return null even in the case of previously listed types of messages. For instance,
  /// if a file is being sent.
  /// return information about the file that is attached to the message
  final Attachment? attachment;

  /// return true if this message is history.
  final bool? isSavedInHistory;

  /// return true if this visitor message is read by operator or this message is not by visitor.
  final bool? isReadByOperator;

  /// return true if this message can be edited.
  final bool? canBeEdited;

  /// return true if this message can be replied.
  final bool? canBeReplied;

  /// return true if this message was edited.
  final bool? isEdited;

  Message({
    required this.clientSideId,
    this.serverSideId,
    required this.senderName,
    required this.type,
    required this.time,
    required this.text,
    required this.sendStatus,
    this.sessionId,
    this.operatorId,
    this.senderAvatarUrl,
    this.attachment,
    this.isSavedInHistory,
    this.isReadByOperator,
    this.canBeEdited,
    this.canBeReplied,
    this.isEdited,
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
  int get hashCode => super.hashCode;

  @override
  int compareTo(other) => time.compareTo(other.time);

  @override
  String toString() {
    return 'Message('
        'clientSideId: $clientSideId , '
        'serverSideId: $serverSideId, '
        'senderName: $senderName, '
        'type: $type, '
        'time: $time, '
        'text: $text, '
        'sendStatus: $sendStatus,'
        'sessionId: $sessionId,'
        'operatorId: $operatorId,'
        'senderAvatarUrl: $senderAvatarUrl,'
        'attachment: $attachment,'
        'isSavedInHistory: $isSavedInHistory,'
        'isReadByOperator: $isReadByOperator,'
        'canBeEdited: $canBeEdited,'
        'canBeReplied: $canBeReplied,'
        'isEdited: $isEdited)';
  }
}

/// Type of [Message]
enum MessageType {
  /// A message from operator which requests some actions from a visitor.
  /// E.g. choose an operator group by clicking on a button in this message.
  /// see [Message.attachment]
  ACTION_REQUEST,

  /// A message from operator which requests some information about a visitor.
  /// see [Message.attachment]
  CONTACT_REQUEST,

  /// A message sent by an operator which contains an attachment.
  /// Notice that the method [Message.attachment] may return null even for messages of this type. For instance,
  /// if a file is being sent.
  /// see [Attachment]
  FILE_FROM_OPERATOR,

  /// A message sent by a visitor which contains an attachment.
  /// Notice that the method [Message.attachment] may return null even for messages of this type. For instance,
  /// if a file is being sent.
  /// see [Attachment]
  FILE_FROM_VISITOR,

  /// A system information message. Messages of this type are automatically sent at specific events.
  /// For example when starting a chat, closing a chat or when an operator joins a chat.
  INFO,

  /// The system message that the chat bot sends.
  KEYBOARD,

  /// A system message from the chat bot containing information about the button that the user selected.
  KEYBOARD_RESPONSE,

  /// A text message sent by an operator.
  OPERATOR,

  /// A system information message which indicates that an operator is busy and can not reply at the moment.
  OPERATOR_BUSY,

  /// A sticker message sent by a visitor.
  STICKER_VISITOR,

  /// A text message sent by a visitor.
  VISITOR,
}

enum SendStatus {
  /// A message is being sent.
  SENDING,

  /// A message had been sent to the server, received by the server and was spreaded among clients.
  SENT,
}

/// Contains a file attached to the message.
class Attachment {
  Attachment({
    required this.fileInfo,
    required this.listFileInfo,
    required this.state,
    this.errorType,
    this.errorMessage,
    this.downloadProgress,
  });

  /// return the fileInfo of the attachment
  final FileInfo fileInfo;

  /// return the filesInfo of the attachment
  final List<FileInfo> listFileInfo;

  /// return type of error in case of problems during attachment upload
  final String? errorType;

  /// return a message with the reason for the error during loading
  final String? errorMessage;

  /// return attachment upload progress as a percentage
  final int? downloadProgress;

  /// return attachment state
  final AttachmentState state;
  
  @override
  String toString() {
    return 'Attachment('
        'fileInfo: $fileInfo, '
        'listFileInfo: $listFileInfo, '
        'state: $state, '
        'errorType: $errorType, '
        'errorMessage: $errorMessage, '
        'downloadProgress: $downloadProgress)';
  }
}

/// Shows the state of the attachment.
enum AttachmentState {
  /// Some error occurred during loading
  ERROR,

  /// Sile is available for download
  READY,

  /// The file is uploaded to the server
  UPLOAD,
}

/// Contains information about attachment properties.
class FileInfo {
  FileInfo({
    required this.fileName,
    this.url,
    this.size,
    this.contentType,
    this.imageInfo,
  });

  /// A URL of a file.
  /// Notice that this URL is short-lived and is tied to a session.
  /// return url of the file
  final String? url;

  /// return file size in bytes

  final int? size;

  /// return name of a file

  final String fileName;

  /// return MIME-type of a file

  final String? contentType;

  /// return if a file is an image, returns information about an image, in other cases returns null

  final ImageInfo? imageInfo;

  @override
  String toString() {
    return 'FileInfo('
        'fileName: $fileName, '
        'url: $url, '
        'size: $size, '
        'contentType: $contentType, '
        'imageInfo: $imageInfo)';
  }
}

/// Contains information about an image.
class ImageInfo {
  ImageInfo({required this.thumbUrl, this.width, this.height});

  ///       Returns a URL of a thumbnail. The maximum width and height is usually 300 pixels but it can be adjusted at server settings.
  ///	 To get an actual preview size before file uploading will be completed, use the following code:
  ///	  ```
  ///           THUMB_SIZE = 300;
  ///           int width = imageInfo.width;
  ///           int height = imageInfo.height;
  ///           if(height > width) {
  ///               width = THUMB_SIZE * width / height;
  ///               height = THUMB_SIZE;
  ///           } else {
  ///               height = THUMB_SIZE * height / width;
  ///               width = THUMB_SIZE;
  ///           }
  ///    ```
  ///	 Notice that this URL is short-lived and is tied to a session.
  ///  return URL уменьшенной копии изображении

  final String thumbUrl;

  /// return width of an image

  final int? width;

  /// return height of an image

  final int? height;

  @override
  String toString() {
    return 'ImageInfo('
        'thumbUrl: $thumbUrl, '
        'width: $width, '
        'height: $height)';
  }
}
