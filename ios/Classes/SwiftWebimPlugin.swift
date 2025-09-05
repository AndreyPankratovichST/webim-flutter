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
            getPlatformVersion (call, result: result)
        case "buildSession":
            buildSession (call, result: result)
        case "pauseSession":
            pauseSession (result: result)
        case "resumeSession":
            resumeSession (result: result)
        case "disposeSession":
            destroySession (result: result)
        case "sendMessage":
            sendMessage (call, result: result)
        case "sendFile":
            sendFile(call, result: result)
        case "getLastMessages":
            getLastMessages (call, result: result)
        case "getNextMessages":
            getNextMessages (call, result: result)
        default:
            print("not implemented")
        }
        
    }
    
    private func getPlatformVersion(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        result("iOS! " + UIDevice.current.systemVersion)
    }
    
    private func resumeSession(result: @escaping FlutterResult){
        if(SwiftWebimPlugin.session == nil) {
            result(FlutterError(
                    code: FlutterPluginEnum.failure,
                    message: "Session not exist",
                    details: nil))
        }
        do{
            try SwiftWebimPlugin.session?.resume()
            _ = try SwiftWebimPlugin.session?.getStream().newMessageTracker(messageListener: SwiftWebimPlugin.messageStreamHandler)
        }catch{
            result(FlutterError(
                    code: FlutterPluginEnum.failure,
                    message: "Resume session failed",
                    details: nil))
            
        }
        result(nil)
    }
    
    private func pauseSession(result: @escaping FlutterResult){
        if(SwiftWebimPlugin.session == nil) {
            result(FlutterError(
                    code: FlutterPluginEnum.failure,
                    message: "Session not exist",
                    details: nil))
        }
        do{
            try SwiftWebimPlugin.session?.pause()
        }catch{
            result(FlutterError(
                    code: FlutterPluginEnum.failure,
                    message: "Pause session failed",
                    details: nil))
            
        }
        result(nil)
    }
    
    private func destroySession(result: @escaping FlutterResult){
        do{
            try SwiftWebimPlugin.session?.destroy()
            
        }catch{
            result(FlutterError(
                    code: FlutterPluginEnum.failure,
                    message: "Pause session failed",
                    details: nil))
            
        }
        result(nil)
    }
    
    
    private func getLastMessages(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        let args = call.arguments as! [String: Any]
        let limit = args["LIMIT"] as! Int
        
        SwiftWebimPlugin.tracker = try? SwiftWebimPlugin.session?.getStream().newMessageTracker(messageListener: WebimMessageListener())
        
        try? SwiftWebimPlugin.tracker?.getLastMessages(byLimit: limit, completion: {(messages: [Message]) -> Void in self.complete(messages, result)})
    }
    
    
    
    private func getNextMessages(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        let args = call.arguments as! [String: Any]
        let limit = args["LIMIT"] as! Int
        
        try? SwiftWebimPlugin.tracker?.getNextMessages(byLimit: limit, completion: {(messages: [Message]) -> Void in self.complete(messages, result)})
    }
    
    
    private func complete(_ messages: [Message],_  result: @escaping FlutterResult) -> Void {
        
        do{
            let json = try JSONSerialization.data(withJSONObject: messages.map{item in item.toJson()}, options: .prettyPrinted)
            
            result(String(data: json, encoding: .utf8))
        }catch {
            result(FlutterError(
                    code: FlutterPluginEnum.failure,
                    message: "Json serialization of messase failed",
                    details: nil))
        }
    }
    
    
    private func sendMessage(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        let args = call.arguments as! [String: Any]
        let message = args["MESSAGE"] as! String
        
        let response = try? SwiftWebimPlugin.session?.getStream().send(message: message)
        
        result(response ?? "error")
    }

    private func sendFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["FILE_PATH"] as? String else {
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

            try session.getStream().send(
                file: fileData,
                fileName: fileName,
                mimeType: mimeType,
                completionHandler: { messageID in
                    result(messageID)
                }
            )
        } catch {
            result(FlutterError(
                code: "SEND_FILE_ERROR",
                message: "Failed to send file: \(error.localizedDescription)",
                details: nil))
        }
    }
    
    private func buildSession(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        if(SwiftWebimPlugin.session != nil){
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
        
        if(visitorFields != nil) {sessionBuilder.set(visitorFieldsJSONString: visitorFields!)}
        
        sessionBuilder.build(
            onSuccess: { webimSession in
                SwiftWebimPlugin.session = webimSession
                self.resumeSession(result: result)
            }, onError: {
                error in
                switch error{
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

    private func getMimeTypeFromExtension(_ extension: String) -> String {
        switch extension.lowercased() {
            case "jpg", "jpeg": return "image/jpeg"
            case "png": return "image/png"
            case "gif": return "image/gif"
            case "pdf": return "application/pdf"
            case "doc", "docx": return "application/msword"
            case "xls", "xlsx": return "application/vnd.ms-excel"
            case "ppt", "pptx": return "application/vnd.ms-powerpoint"
            case "txt": return "text/plain"
            case "zip": return "application/zip"
            case "mp3": return "audio/mpeg"
            case "mp4": return "video/mp4"
            case "mov": return "video/quicktime"
            default: return "application/octet-stream"
        }
    }
}

class WebimMessageListener :NSObject, FlutterStreamHandler, MessageListener{
    
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

extension Message{
    
    func convertMessageTypeToString(_ type: MessageType) -> String {
        switch type {
        case .actionRequest:
            return "ACTION_REQUEST"
        case .contactInformationRequest:
            return "CONTACT_REQUEST"
        case .keyboard:
            return "KEYBOARD"
        case .keyboardResponse:
            return "KEYBOARD_RESPONSE"
        case .fileFromOperator:
            return "FILE_FROM_OPERATOR"
        case .fileFromVisitor:
            return "FILE_FROM_VISITOR"
        case .info:
            return "INFO"
        case .operatorMessage:
            return "OPERATOR"
        case .operatorBusy:
            return "OPERATOR_BUSY"
        case .visitorMessage:
            return "VISITOR"
        @unknown default:
            return "UNKNOWN"
        }
    }
    
    func toJson() -> [String : Any]{
        
        let timeMicroseconds = (getTime().timeIntervalSince1970 * 1000000).rounded()
        
        let map =  [
            "clientSideId": ["id": getID()],
            "text": getText(),
            "currentChatId": getCurrentChatID() ?? "",
            "operatorId": getOperatorID() ?? "",
            "senderAvatarUrl":getSenderAvatarFullURL()?.absoluteString ?? "",
            "senderName":getSenderName(),
            "sendStatus":(getSendStatus() == MessageSendStatus.sent) ? "SENT" : "SENDING",
            "timeMicros": Int64(timeMicroseconds),
            "isReadOperator":isReadByOperator(),
            "canBeEdited": canBeEdited(),
            "canBeReplied": canBeReplied(),
            "edited": isEdited(),
            "readByOperator": isReadByOperator(),
            "serverSideId": getID(),
            "type": convertMessageTypeToString(getType()),
        ] as [String : Any]
        return map
    }
    
}
