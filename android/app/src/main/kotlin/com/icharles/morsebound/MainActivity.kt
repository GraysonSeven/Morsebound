package com.icharles.morsebound

import android.content.Intent
import android.net.Uri
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL =
            "com.icharles.morsebound/app_update"
    }

    private lateinit var appUpdateManager: AppUpdateManager
    private var updateChannel: MethodChannel? = null

    private val installStateListener = InstallStateUpdatedListener { state ->
        if (state.installStatus() == InstallStatus.DOWNLOADED) {
            updateChannel?.invokeMethod("updateDownloaded", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        appUpdateManager = AppUpdateManagerFactory.create(this)
        appUpdateManager.registerListener(installStateListener)

        updateChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkForUpdate" -> checkForUpdate(result)
                    "startFlexibleUpdate" -> startFlexibleUpdate(result)
                    "completeUpdate" -> completeUpdate(result)
                    "openExternalUrl" -> {
                        openExternalUrl(call.argument<String>("url"), result)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun checkForUpdate(result: MethodChannel.Result) {
        appUpdateManager.appUpdateInfo
            .addOnSuccessListener { info ->
                result.success(
                    mapOf(
                        "supported" to true,
                        "available" to
                            (info.updateAvailability() ==
                                UpdateAvailability.UPDATE_AVAILABLE),
                        "downloaded" to
                            (info.installStatus() ==
                                InstallStatus.DOWNLOADED),
                        "flexibleAllowed" to
                            info.isUpdateTypeAllowed(
                                AppUpdateType.FLEXIBLE,
                            ),
                        "immediateAllowed" to
                            info.isUpdateTypeAllowed(
                                AppUpdateType.IMMEDIATE,
                            ),
                        "priority" to info.updatePriority(),
                        "stalenessDays" to
                            info.clientVersionStalenessDays(),
                    ),
                )
            }
            .addOnFailureListener { error ->
                result.error(
                    "PLAY_UPDATE_CHECK_FAILED",
                    error.message,
                    null,
                )
            }
    }

    private fun startFlexibleUpdate(result: MethodChannel.Result) {
        appUpdateManager.appUpdateInfo
            .addOnSuccessListener { info ->
                val available =
                    info.updateAvailability() ==
                        UpdateAvailability.UPDATE_AVAILABLE
                val allowed =
                    info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)

                if (!available || !allowed) {
                    result.success(false)
                    return@addOnSuccessListener
                }

                val options = AppUpdateOptions
                    .newBuilder(AppUpdateType.FLEXIBLE)
                    .build()

                appUpdateManager
                    .startUpdateFlow(info, this, options)
                    .addOnSuccessListener {
                        result.success(true)
                    }
                    .addOnFailureListener { error ->
                        result.error(
                            "PLAY_UPDATE_START_FAILED",
                            error.message,
                            null,
                        )
                    }
            }
            .addOnFailureListener { error ->
                result.error(
                    "PLAY_UPDATE_INFO_FAILED",
                    error.message,
                    null,
                )
            }
    }

    private fun openExternalUrl(
        url: String?,
        result: MethodChannel.Result,
    ) {
        if (url.isNullOrBlank()) {
            result.success(false)
            return
        }

        try {
            val uri = Uri.parse(url)
            if (uri.scheme != "https") {
                result.error("UNSAFE_UPDATE_URL", "Only HTTPS update links are allowed.", null)
                return
            }
            startActivity(
                Intent(Intent.ACTION_VIEW, uri).apply {
                    addCategory(Intent.CATEGORY_BROWSABLE)
                },
            )
            result.success(true)
        } catch (error: Exception) {
            result.error("OPEN_UPDATE_URL_FAILED", error.message, null)
        }
    }

    private fun completeUpdate(result: MethodChannel.Result) {
        appUpdateManager
            .completeUpdate()
            .addOnSuccessListener { result.success(true) }
            .addOnFailureListener { error ->
                result.error(
                    "PLAY_UPDATE_COMPLETE_FAILED",
                    error.message,
                    null,
                )
            }
    }

    override fun onResume() {
        super.onResume()

        if (!::appUpdateManager.isInitialized) return

        appUpdateManager.appUpdateInfo
            .addOnSuccessListener { info ->
                if (info.installStatus() == InstallStatus.DOWNLOADED) {
                    updateChannel?.invokeMethod(
                        "updateDownloaded",
                        null,
                    )
                }
            }
    }

    override fun onDestroy() {
        if (::appUpdateManager.isInitialized) {
            appUpdateManager.unregisterListener(installStateListener)
        }
        updateChannel = null
        super.onDestroy()
    }
}
