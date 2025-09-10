import Flutter
import UIKit
import WebimMobileSDK
import UniformTypeIdentifiers

let methodChannelName = "webim"
let eventStreamChannelName = "webim.stream"

public class SwiftWebimPlugin: NSObject, FlutterPlugin, WebimLogger {

    static var session: WebimSession?
    static var tracker: MessageTracker?
    static let messageStreamHandler = WebimMessageListener()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
        let instance = SwiftWebimPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventStreamChannel = FlutterEventChannel(name: eventStreamChannelName, binaryMessenger: registrar.messenger())
        eventStreamChannel.setStreamHandler(messageStreamHandler)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            getPlatformVersion(call, result: result)
        case "buildSession":
            buildSession(call, result: result)
        case "pauseSession":
            pauseSession(result: result)
        case "resumeSession":
            resumeSession(result: result)
        case "disposeSession":
            destroySession(result: result)
        case "sendMessage":
            sendMessage(call, result: result)
        case "sendFile":
            sendFile(call, result: result)
        case "getLastMessages":
            getLastMessages(call, result: result)
        case "getNextMessages":
            getNextMessages(call, result: result)
        default:
            print("not implemented")
        }

    }

    private func getPlatformVersion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result("iOS! " + UIDevice.current.systemVersion)
    }

    private func resumeSession(result: @escaping FlutterResult) {
        if (SwiftWebimPlugin.session == nil) {
            result(FlutterError(
                code: FlutterPluginEnum.failure,
                message: "Session not exist",
                details: nil))
        }
        do {
            try SwiftWebimPlugin.session?.resume()
            _ = try SwiftWebimPlugin.session?.getStream().newMessageTracker(messageListener: SwiftWebimPlugin.messageStreamHandler)
        } catch {
            result(FlutterError(
                code: FlutterPluginEnum.failure,
                message: "Resume session failed",
                details: nil))

        }
        result(nil)
    }

    private func pauseSession(result: @escaping FlutterResult) {
        if (SwiftWebimPlugin.session == nil) {
            result(FlutterError(
                code: FlutterPluginEnum.failure,
                message: "Session not exist",
                details: nil))
        }
        do {
            try SwiftWebimPlugin.session?.pause()
        } catch {
            result(FlutterError(
                code: FlutterPluginEnum.failure,
                message: "Pause session failed",
                details: nil))

        }
        result(nil)
    }

    private func destroySession(result: @escaping FlutterResult) {
        do {
            try SwiftWebimPlugin.session?.destroy()

        } catch {
            result(FlutterError(
                code: FlutterPluginEnum.failure,
                message: "Pause session failed",
                details: nil))

        }
        result(nil)
    }


    private func getLastMessages(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let limit = args["LIMIT"] as! Int

        SwiftWebimPlugin.tracker = try? SwiftWebimPlugin.session?.getStream().newMessageTracker(messageListener: WebimMessageListener())

        try? SwiftWebimPlugin.tracker?.getLastMessages(byLimit: limit, completion: { (messages: [Message]) -> Void in self.complete(messages, result) })
    }


    private func getNextMessages(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let limit = args["LIMIT"] as! Int

        try? SwiftWebimPlugin.tracker?.getNextMessages(byLimit: limit, completion: { (messages: [Message]) -> Void in self.complete(messages, result) })
    }


    private func complete(_ messages: [Message], _ result: @escaping FlutterResult) -> Void {

        do {
            let json = try JSONSerialization.data(withJSONObject: messages.map { item in
                item.toJson()
            }, options: .prettyPrinted)

            result(String(data: json, encoding: .utf8))
        } catch {
            result(FlutterError(
                code: FlutterPluginEnum.failure,
                message: "Json serialization of messase failed",
                details: nil))
        }
    }


    private func sendMessage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let message = args["MESSAGE"] as! String

        let response = try? SwiftWebimPlugin.session?.getStream().send(message: message)

        result(response ?? "error")
    }

    private func sendFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["FILE_PATH"] as? String
        else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing or invalid filePath parameter",
                details: nil))
            return
        }

        let fileURL = URL(fileURLWithPath: filePath)

        guard FileManager.default.fileExists(atPath: filePath) else {
            result(FlutterError(
                code: "FILE_NOT_FOUND",
                message: "File does not exist at path: \(filePath)",
                details: nil))
            return
        }

        let fileName = fileURL.lastPathComponent
        let mimeType = getMimeTypeForFile(url: fileURL) ?? "application/octet-stream"

        guard let session = SwiftWebimPlugin.session else {
            result(FlutterError(
                code: "NO_SESSION",
                message: "Webim session is not initialized",
                details: nil))
            return
        }

        do {
            let fileData = try Data(contentsOf: fileURL)

            let completionHandler = SendFileCompletionHandlerWrapper(result: result)

            try session.getStream().send(
                file: fileData,
                filename: fileName,
                mimeType: mimeType,
                completionHandler: completionHandler
            )
        } catch {
            result(FlutterError(
                code: "SEND_FILE_ERROR",
                message: "Failed to send file: \(error.localizedDescription)",
                details: nil))
        }
    }

    private func buildSession(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (SwiftWebimPlugin.session != nil) {
            try! SwiftWebimPlugin.session?.destroy()
        }
        let args = call.arguments as! [String: Any]
        let accountName = args["ACCOUNT_NAME"] as! String
        let locationName = args["LOCATION_NAME"] as! String
        let visitorFields = args["VISITOR"] as? String

        let sessionBuilder = Webim.newSessionBuilder()
            .set(accountName: accountName)
            .set(location: locationName)
            .set(webimLogger: self, verbosityLevel: .verbose)

        if (visitorFields != nil) {
            sessionBuilder.set(visitorFieldsJSONString: visitorFields!)
        }

        sessionBuilder.build(
            onSuccess: { webimSession in
                SwiftWebimPlugin.session = webimSession
                self.resumeSession(result: result)
            }, onError: {
            error in
            switch error {
            case .nilAccountName:
                result(FlutterError(code: FlutterPluginEnum.failure,
                                    message: "Webim session object creating failed because of passing nil account name.",
                                    details: nil))


            case .nilLocation:
                result(FlutterError(code: FlutterPluginEnum.failure,
                                    message: "Webim session object creating failed because of passing nil location name.",
                                    details: nil))

            case .invalidRemoteNotificationConfiguration:
                result(FlutterError(code: FlutterPluginEnum.failure,
                                    message: "Webim session object creating failed because of invalid remote notifications configuration.",
                                    details: nil))

            case .invalidAuthentificatorParameters:
                result(FlutterError(code: FlutterPluginEnum.failure,
                                    message: "Webim session object creating failed because of invalid visitor authentication system configuration.",
                                    details: nil))

            case .invalidHex:
                result(FlutterError(code: FlutterPluginEnum.failure,
                                    message: "Webim can't parsed prechat fields",
                                    details: nil))

            case .unknown:
                result(FlutterError(code: FlutterPluginEnum.failure,
                                    message: "Webim session object creating failed with unknown error",
                                    details: nil))
            }
        }
        )

    }

    // MARK: - WebimLogger
    public func log(entry: String) {
        print(entry)
    }

    private func getMimeTypeForFile(url: URL) -> String? {
        if #available(iOS 14.0, *) {
            if let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
               let utType = resourceValues.contentType {
                return utType.preferredMIMEType
            }

            if let utType = UTType(filenameExtension: url.pathExtension) {
                return utType.preferredMIMEType
            }
        } else {
            let pathExtension = url.pathExtension.lowercased()
            return getMimeTypeFromExtension(pathExtension)
        }

        return nil
    }

    private func getMimeTypeFromExtension(_ fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "pdf": return "application/pdf"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls": return "application/vnd.ms-excel"
        case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "ppt": return "application/vnd.ms-powerpoint"
        case "pptx": return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "txt": return "text/plain"
        case "zip": return "application/zip"
        case "mp3": return "audio/mpeg"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        default: return "application/octet-stream"
        }
    }
}

class SendFileCompletionHandlerWrapper: NSObject, SendFileCompletionHandler {
    private let result: FlutterResult

    init(result: @escaping FlutterResult) {
        self.result = result
    }

    func onSuccess(messageID: String) {
        result(messageID)
    }

    func onFailure(messageID: String, error: SendFileError) {
        result(FlutterError(
            code: "SEND_FILE_ERROR",
            message: "Failed to send file: \(error.localizedDescription)",
            details: messageID
        ))
    }
}

class WebimMessageListener: NSObject, FlutterStreamHandler, MessageListener {

    private var _eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        _eventSink = nil
        return nil
    }

    public func added(message newMessage: Message, after previousMessage: Message?) {
        _eventSink?(["added": newMessage.toJson()])
    }

    public func removed(message: Message) {
        _eventSink?(["removed": message.toJson()])
    }

    public func removedAllMessages() {
        _eventSink?(["removedAll": nil])
    }

    public func changed(message oldVersion: Message, to newVersion: Message) {
        _eventSink?([
                        "from": oldVersion.toJson(),
                        "to": newVersion.toJson(),
                    ]
        )
        print(oldVersion)
        print(newVersion)
    }
}

extension Message {
    func toJson() -> [String: Any] {
        var attachmentInfo: [String: Any]?
        if let messageData = self.getData(), let attachment = messageData.getAttachment() {
            var filesList: [[String: Any]] = []

            let filesInfo = attachment.getFilesInfo()
            for fileInfo in filesInfo {
                filesList.append(convertFileInfoToMap(fileInfo: fileInfo))
            }

            attachmentInfo = [
                "state": convertAttachmentStateToString(attachment.getState()),
                "filesInfo": convertFileInfoToMap(fileInfo: attachment.getFileInfo()),
                "filesList": filesList,
                "errorType": attachment.getErrorType() as Any,
                "errorMessage": attachment.getErrorMessage() as Any,
                "visitorErrorMessage": attachment.getVisitorErrorMessage() as Any,
                "downloadProgress": attachment.getDownloadProgress() as Any,
                "extraText": NSNull() // Not available in the protocol
            ]

        }

        var quoteInfo: [String: Any]?
        if let quote = self.getQuote() {
            var messageAttachmentInfo: [String: Any]?
            if let messageAttachment = quote.getMessageAttachment() {
                messageAttachmentInfo = convertFileInfoToMap(fileInfo: messageAttachment)
            }

            quoteInfo = [
                "state": convertQuoteStateToString(quote.getState()),
                "messageAttachment": messageAttachmentInfo as Any,
                "messageId": quote.getMessageID() as Any,
                "messageType": quote.getMessageType() != nil ? convertMessageTypeToString(quote.getMessageType()!) : NSNull(),
                "senderName": quote.getSenderName() as Any,
                "messageText": quote.getMessageText() as Any,
                "messageTimestamp": quote.getMessageTimestamp() != nil ? Int(quote.getMessageTimestamp()!.timeIntervalSince1970 * 1000) : NSNull(),
                "quotedMessageId": quote.getAuthorID() as Any // Using authorID as quotedMessageId
            ]
        }

        var keyboardInfo: [String: Any]?
        if let keyboard = self.getKeyboard() {
            var buttonsArray: [[[String: Any]]] = []

            let buttons = keyboard.getButtons()
            for row in buttons {
                var rowArray: [[String: Any]] = []
                for button in row {
                    rowArray.append(convertKeyboardButtonToMap(button: button))
                }
                buttonsArray.append(rowArray)
            }

            var keyboardResponseInfo: [String: Any]?
            if let keyboardResponse = keyboard.getResponse() {
                keyboardResponseInfo = [
                    "buttonId": keyboardResponse.getButtonID(),
                    "messageId": keyboardResponse.getMessageID()
                ]
            }

            keyboardInfo = [
                "buttons": buttonsArray,
                "state": convertKeyboardStateToString(keyboard.getState()),
                "keyboardResponse": keyboardResponseInfo as Any
            ]
        }

        var keyboardRequestInfo: [String: Any]?
        if let keyboardRequest = self.getKeyboardRequest() {
            let button = keyboardRequest.getButton()
            let buttonInfo = convertKeyboardButtonToMap(button: button)

            keyboardRequestInfo = [
                "buttons": buttonInfo,
                "messageId": keyboardRequest.getMessageID()
            ]
        }

        var stickerInfo: [String: Any]?
        if let sticker = self.getSticker() {
            stickerInfo = [
                "stickerId": sticker.getStickerId()
            ]
        }

        var groupDataInfo: [String: Any]?
        if let group = self.getGroup() {
            groupDataInfo = [
                "groupId": group.getID(),
                "messageCount": group.getMessageCount(),
                "messageNumber": group.getMessageNumber()
            ]
        }

        var reactionInfo: String?
        if let reaction = self.getVisitorReaction() {
            reactionInfo = reaction
        }

        let timeInMilliseconds = Int(self.getTime().timeIntervalSince1970 * 1000)

        return [
            "clientSideId": ["id": self.getID()],
            "sessionId": self.getCurrentChatID() ?? NSNull(),
            "serverSideId": self.getServerSideID() ?? NSNull(),
            "operatorId": self.getOperatorID() ?? NSNull(),
            "senderAvatarUrl": self.getSenderAvatarFullURL()?.absoluteString ?? NSNull(),
            "senderName": self.getSenderName(),
            "type": convertMessageTypeToString(self.getType()),
            "time": timeInMilliseconds,
            "text": self.getText(),
            "sendStatus": convertSendStatusToString(self.getSendStatus()),
            "data": convertMessageDataToString(self.getData()) ?? NSNull(),
            "savedInHistory": false,
            "readByOperator": self.isReadByOperator(),
            "canBeEdited": self.canBeEdited(),
            "canBeReplied": self.canBeReplied(),
            "edited": self.isEdited(),
            "quote": quoteInfo ?? NSNull(),
            "reaction": reactionInfo ?? NSNull(),
            "canVisitorReact": self.canVisitorReact(),
            "canVisitorChangeReaction": self.canVisitorChangeReaction(),
            "groupData": groupDataInfo ?? NSNull(),
            "keyboard": keyboardInfo ?? NSNull(),
            "keyboardRequest": keyboardRequestInfo ?? NSNull(),
            "sticker": stickerInfo ?? NSNull(),
            "attachment": attachmentInfo ?? NSNull()
        ]
    }

    private func convertMessageDataToString(_ messageData: MessageData?) -> String? {
        guard let messageData = messageData else {
            return nil
        }

        if let attachment = messageData.getAttachment() {
            let fileInfo = attachment.getFileInfo()
            return "File: \(fileInfo.getFileName()), Size: \(fileInfo.getSize() ?? 0), Type: \(fileInfo.getContentType() ?? "unknown")"
        }

        return nil
    }

    private func convertFileInfoToMap(fileInfo: FileInfo) -> [String: Any] {
        var imageInfoMap: [String: Any]?

        if let imageInfo = fileInfo.getImageInfo() {
            imageInfoMap = [
                "thumbUrl": imageInfo.getThumbURL()?.absoluteString as Any,
                "width": imageInfo.getWidth() as Any,
                "height": imageInfo.getHeight() as Any
            ]
        }

        return [
            "url": fileInfo.getURL()?.absoluteString as Any,
            "size": fileInfo.getSize() as Any,
            "fileName": fileInfo.getFileName(),
            "contentType": fileInfo.getContentType() as Any,
            "imageInfo": imageInfoMap as Any
        ]
    }

    private func convertKeyboardButtonToMap(button: KeyboardButton) -> [String: Any] {
        var configurationInfo: [String: Any]?
        if let configuration = button.getConfiguration() {
            configurationInfo = [
                "buttonType": convertKeyboardButtonTypeToString(configuration.getButtonType()),
                "data": configuration.getData() as Any,
                "state": convertKeyboardButtonStateToString(configuration.getState())
            ]
        }

        var paramsInfo: [String: Any]?
        if let params = button.getParams() {
            paramsInfo = [
                "type": convertKeyboardButtonParamsTypeToString(params.getType()),
                "action": params.getAction() as Any,
                "color": params.getColor() as Any
            ]
        }

        return [
            "id": button.getID(),
            "text": button.getText(),
            "configuration": configurationInfo as Any,
            "params": paramsInfo as Any
        ]
    }

    private func convertMessageTypeToString(_ type: MessageType) -> String {
        switch type {
        case .actionRequest: return "ACTION_REQUEST"
        case .contactInformationRequest: return "CONTACT_REQUEST"
        case .keyboard: return "KEYBOARD"
        case .keyboardResponse: return "KEYBOARD_RESPONSE"
        case .fileFromOperator: return "FILE_FROM_OPERATOR"
        case .fileFromVisitor: return "FILE_FROM_VISITOR"
        case .info: return "INFO"
        case .operatorMessage: return "OPERATOR"
        case .operatorBusy: return "OPERATOR_BUSY"
        case .visitorMessage: return "VISITOR"
        case .stickerVisitor: return "STICKER_VISITOR"
        @unknown default: return "UNKNOWN"
        }
    }

    private func convertSendStatusToString(_ status: MessageSendStatus) -> String {
        switch status {
        case .sending: return "SENDING"
        case .sent: return "SENT"
        @unknown default: return "UNKNOWN"
        }
    }

    private func convertAttachmentStateToString(_ state: AttachmentState) -> String {
        switch state {
        case .error: return "ERROR"
        case .ready: return "READY"
        case .upload: return "UPLOAD"
        case .externalChecks: return "EXTERNAL_CHECKS"
        @unknown default: return "UNKNOWN"
        }
    }

    private func convertQuoteStateToString(_ state: QuoteState) -> String {
        switch state {
        case .pending: return "PENDING"
        case .filled: return "FILLED"
        case .notFound: return "NOT_FOUND"
        @unknown default: return "UNKNOWN"
        }
    }

    private func convertKeyboardStateToString(_ state: KeyboardState) -> String {
        switch state {
        case .pending: return "PENDING"
        case .completed: return "COMPLETED"
        case .canceled: return "CANCELLED"
        @unknown default: return "UNKNOWN"
        }
    }

    private func convertKeyboardButtonTypeToString(_ type: ButtonType?) -> String {
        guard let type = type else {
            return "UNKNOWN"
        }

        switch type {
        case .url: return "URL_BUTTON"
        case .insert: return "INSERT_BUTTON"
        @unknown default: return "UNKNOWN"
        }
    }

    private func convertKeyboardButtonStateToString(_ state: ButtonState?) -> String {
        guard let state = state else {
            return "UNKNOWN"
        }

        switch state {
        case .showing: return "SHOWING"
        case .showingSelected: return "SHOWING_SELECTED"
        case .hidden: return "HIDDEN"
        @unknown default: return "UNKNOWN"
        }
    }

    private func convertKeyboardButtonParamsTypeToString(_ type: ParamsButtonType?) -> String {
        guard let type = type else {
            return "UNKNOWN"
        }

        switch type {
        case .url: return "URL"
        case .action: return "ACTION"
        @unknown default: return "UNKNOWN"
        }
    }
}
