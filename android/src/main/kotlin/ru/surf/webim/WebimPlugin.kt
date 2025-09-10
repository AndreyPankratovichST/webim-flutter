package ru.surf.webim

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.google.gson.Gson
import ru.webim.android.sdk.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.net.URLConnection

const val methodChannelName = "webim"
const val eventMessageStreamName = "webim.stream"

/** WebimPlugin */
class WebimPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    private var session: WebimSession? = null
    private val messageDelegate = MessageTrackerDelegate()
    private var tracker: MessageTracker? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, methodChannelName)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        EventChannel(flutterPluginBinding.binaryMessenger, eventMessageStreamName).setStreamHandler(
            messageDelegate
        )
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> getPlatformVersion(call, result)
            "buildSession" -> {
                buildSession(call, result)
            }
            "pauseSession" -> pauseSession()
            "resumeSession" -> resumeSession()
            "disposeSession" -> disposeSession()
            "sendMessage" -> sendMessage(call, result)
            "sendFile" -> sendFile(call, result)
            "getLastMessages" -> getLastMessages(call, result)
            "getNextMessages" -> getNextMessages(call, result)
            else -> result.notImplemented()
        }
    }


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun getPlatformVersion(@NonNull call: MethodCall, @NonNull result: Result) {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
    }

    private fun buildSession(@NonNull call: MethodCall, @NonNull result: Result) {
        val location = call.argument<String?>("LOCATION_NAME") as String
        val accountName = call.argument<String?>("ACCOUNT_NAME") as String
        val visitorFields = call.argument<String?>("VISITOR")

        val sessionBuilder = Webim.newSessionBuilder()
            .setContext(context)
            .setAccountName(accountName)
            .setLocation(location)
            .setLogger(if (BuildConfig.DEBUG)
                WebimLog { log: String -> Log.d("WEBIM", log) } else null,
                Webim.SessionBuilder.WebimLogVerbosityLevel.VERBOSE
            )
        if (visitorFields != null && visitorFields.isNotEmpty()) sessionBuilder.setVisitorFieldsJson(
            visitorFields
        )
        val webimSession = sessionBuilder.build()

        session = webimSession

        resumeSession()
        result.success(session?.toString())
    }

    private fun pauseSession() {
        session?.pause()
    }

    private fun resumeSession() {
        session?.resume()
        tracker = session?.stream?.newMessageTracker(messageDelegate)
    }

    private fun disposeSession() {
        session?.destroy()
    }

    private fun sendMessage(@NonNull call: MethodCall, @NonNull result: Result) {
        val message = call.argument<String?>("MESSAGE") as String

        val messageId = session?.stream?.sendMessage(message)

        result.success(messageId.toString())
    }

    private fun sendFile(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            val filePath = call.argument<String>("FILE_PATH") ?: ""

            if (filePath.isEmpty()) {
                result.error("INVALID_ARGUMENT", "File path cannot be empty", null)
                return
            }

            val file = File(filePath)

            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "File does not exist at path: $filePath", null)
                return
            }

            val fileName = file.name

            val mimeType = URLConnection.guessContentTypeFromName(fileName) ?: "application/octet-stream"


            val webimSession = session ?: run {
                result.error("SESSION_ERROR", "Webim session is not initialized", null)
                return
            }

            webimSession.stream.sendFile(
                file,
                fileName,
                mimeType,
                object : MessageStream.SendFileCallback {
                    override fun onProgress(
                        id: Message.Id,
                        sentBytes: Long
                    ) {}

                    override fun onSuccess(messageId: Message.Id) {
                        result.success(messageId.toString())
                    }

                    override fun onFailure(
                        messageId: Message.Id,
                        error: WebimError<MessageStream.SendFileCallback.SendFileError?>
                    ) {
                        result.error("SEND_FILE_ERROR", error.errorString, messageId.toString())
                    }
                }
            )
        } catch (e: Exception) {
            result.error("SEND_FILE_EXCEPTION", e.message, null)
        }
    }

    private fun getLastMessages(@NonNull call: MethodCall, @NonNull result: Result) {
        val limit = call.argument<String?>("LIMIT") as Int

        if (session == null) return
        tracker?.getLastMessages(
            limit
        ) { it: MutableList<out Message> -> result.success(it.toJson()) }
    }

    private fun getNextMessages(@NonNull call: MethodCall, @NonNull result: Result) {
        val limit = call.argument<String?>("LIMIT") as Int

        if (session == null) return
        tracker?.getNextMessages(
            limit
        ) { it: MutableList<out Message> -> result.success(it.toJson()) }
    }
}


private fun Message.toJson(): String {
    val gson = Gson()

    val attachmentInfo =  attachment?.let  { attachment ->
        val filesInfo = attachment.filesInfo
        val filesList = if (filesInfo.isNotEmpty()) {
            filesInfo.map { fileInfo ->
                convertFileInfoToMap(fileInfo)
            }
        } else {
            emptyList<Map<String, Any?>>()
        }

        mapOf(
            "state" to attachment.state.name,
            "filesInfo" to convertFileInfoToMap(attachment.fileInfo),
            "filesList" to filesList,
            "errorType" to attachment.errorType,
            "errorMessage" to attachment.errorMessage,
            "visitorErrorMessage" to attachment.visitorErrorMessage,
            "downloadProgress" to attachment.downloadProgress,
            "extraText" to attachment.extraText
        )
    }

    val quoteInfo = quote?.let { quote ->
        mapOf(
            "state" to quote.state.name,
            "messageAttachment" to quote.messageAttachment?.let { convertFileInfoToMap(it) },
            "messageId" to quote.messageId,
            "messageType" to quote.messageType?.name,
            "senderName" to quote.senderName,
            "messageText" to quote.messageText,
            "messageTimestamp" to quote.messageTimestamp,
            "quotedMessageId" to quote.quotedMessageId
        )
    }

    val keyboardInfo = keyboard?.let { keyboard ->
        mapOf(
            "buttons" to keyboard.buttons?.map { row ->
                row.map { button ->
                    mapOf(
                        "id" to button.id,
                        "text" to button.text,
                        "configuration" to button.configuration?.let { config ->
                            mapOf(
                                "buttonType" to config.buttonType.name,
                                "data" to config.data,
                                "state" to config.state.name
                            )
                        },
                        "params" to button.params?.let { params ->
                            mapOf(
                                "type" to params.type.name,
                                "action" to params.action,
                                "color" to params.color
                            )
                        }
                    )
                }
            },
            "state" to keyboard.state?.name,
            "keyboardResponse" to keyboard.keyboardResponse?.let { response ->
                mapOf(
                    "buttonId" to response.buttonId,
                    "messageId" to response.messageId
                )
            }
        )
    }

    val keyboardRequestInfo = keyboardRequest?.let { request ->
        mapOf(
            "buttons" to request.buttons?.let { button ->
                mapOf(
                    "id" to button.id,
                    "text" to button.text,
                    "configuration" to button.configuration?.let { config ->
                        mapOf(
                            "buttonType" to config.buttonType.name,
                            "data" to config.data,
                            "state" to config.state.name
                        )
                    },
                    "params" to button.params?.let { params ->
                        mapOf(
                            "type" to params.type.name,
                            "action" to params.action,
                            "color" to params.color
                        )
                    }
                )
            },
            "messageId" to request.messageId
        )
    }

    val stickerInfo = sticker?.let { sticker ->
        mapOf(
            "stickerId" to sticker.stickerId
        )
    }

    val map = mapOf(
        "clientSideId" to mapOf("id" to clientSideId.toString()),
        "sessionId" to sessionId,
        "serverSideId" to serverSideId,
        "operatorId" to operatorId?.toString(),
        "senderAvatarUrl" to senderAvatarUrl,
        "senderName" to senderName,
        "type" to type.name,
        "time" to time,
        "text" to text,
        "sendStatus" to sendStatus.name,
        "data" to data,
        "savedInHistory" to isSavedInHistory,
        "readByOperator" to isReadByOperator,
        "canBeEdited" to canBeEdited(),
        "canBeReplied" to canBeReplied(),
        "edited" to isEdited,
        "quote" to quoteInfo,
        "reaction" to reaction?.name,
        "canVisitorReact" to canVisitorReact(),
        "canVisitorChangeReaction" to canVisitorChangeReaction(),
        "groupData" to groupData?.let { groupData ->
            mapOf(
                "id" to groupData.id,
                "msgCount" to groupData.msgCount,
                "msgNumber" to groupData.msgNumber,
            )
        },
        "keyboard" to keyboardInfo,
        "keyboardRequest" to keyboardRequestInfo,
        "sticker" to stickerInfo,
        "attachment" to attachmentInfo
    )

    return gson.toJson(map)
}

private fun Message.convertFileInfoToMap(fileInfo: Message.FileInfo): Map<String, Any?> {
    val imageInfo = fileInfo.imageInfo
    val imageInfoMap = if (imageInfo != null) {
        mapOf(
            "thumbUrl" to imageInfo.thumbUrl,
            "width" to imageInfo.width,
            "height" to imageInfo.height
        )
    } else {
        null
    }

    return mapOf(
        "url" to fileInfo.url,
        "size" to fileInfo.size,
        "fileName" to fileInfo.fileName,
        "contentType" to fileInfo.contentType,
        "imageInfo" to imageInfoMap
    )
}

private fun MutableList<out Message>.toJson(): String {
    val gson = Gson()
    return gson.toJson(this)
}

class MessageTrackerDelegate() : MessageListener, EventChannel.StreamHandler {

    var eventSink: EventChannel.EventSink? = null

    override fun messageAdded(before: Message?, message: Message) {
        eventSink?.success(mapOf("added" to message.toJson()))
    }

    override fun messageRemoved(message: Message) {
        eventSink?.success(mapOf("removed" to message.toJson()))
    }

    override fun messageChanged(from: Message, to: Message) {
        eventSink?.success(
            mapOf(
                "from" to from.toJson(),
                "to" to to.toJson()
            )
        )
    }

    override fun allMessagesRemoved() {
        eventSink?.success(mapOf("removedAll" to null))
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }
}

class MessageTrackerStreamHandler : EventChannel.StreamHandler {

    var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

}


