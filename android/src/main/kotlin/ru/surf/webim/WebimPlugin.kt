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
    return gson.toJson(this)
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


