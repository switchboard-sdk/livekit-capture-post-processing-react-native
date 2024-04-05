package com.livekitcapturepostprocessing

import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.facebook.react.ReactActivity
import com.facebook.react.ReactActivityDelegate
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint.fabricEnabled
import com.facebook.react.defaults.DefaultReactActivityDelegate
import com.synervoz.switchboard.sdk.SwitchboardSDK
import com.synervoz.switchboardvoicemod.VoicemodExtension


class MainActivity : ReactActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // This should be called before any SwitchboardSDK is used
        SwitchboardSDK.initialize(this, "clientID", "clientSecret")
        VoicemodExtension.initialize(this, "voicemod license")


        // Check if the permission is already available.
        if (ContextCompat.checkSelfPermission(this, RECORD_AUDIO_PERMISSION)
            != PackageManager.PERMISSION_GRANTED
        ) {

            // Permission is not granted. Request it.
            ActivityCompat.requestPermissions(
                this, arrayOf<String>(RECORD_AUDIO_PERMISSION),
                RECORD_AUDIO_REQUEST_CODE
            )
        } else {
            // Permission has already been granted. Do the related task.
        }
    }

    companion object {
        private const val RECORD_AUDIO_PERMISSION = android.Manifest.permission.RECORD_AUDIO
        private const val RECORD_AUDIO_REQUEST_CODE = 101
    }



  /**
   * Returns the name of the main component registered from JavaScript. This is used to schedule
   * rendering of the component.
   */
  override fun getMainComponentName(): String = "LiveKitCapturePostProcessing"

  /**
   * Returns the instance of the [ReactActivityDelegate]. We use [DefaultReactActivityDelegate]
   * which allows you to enable New Architecture with a single boolean flags [fabricEnabled]
   */
  override fun createReactActivityDelegate(): ReactActivityDelegate =
      DefaultReactActivityDelegate(this, mainComponentName, fabricEnabled)

}
